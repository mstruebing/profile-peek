#[macro_use]
extern crate rocket;

use rocket::fs::{relative, FileServer};
use serde::Serialize;

mod cors;
mod env;
mod faceit;
mod redis;
mod steam;
mod tracking;

#[derive(Serialize)]
struct Player {
    steam_id: String,
    faceit_data: Option<faceit::FaceitResponse>,
    sites: Vec<Site>,
}

#[derive(Serialize)]
struct Site {
    url: String,
    title: String,
}

/// Catches all OPTION requests in order to get the CORS related Fairing triggered.
#[options("/<_..>")]
fn all_options() {
    /* Intentionally left empty */
}

#[launch]
fn rocket() -> _ {
    env::ensure_set();
    let rocket_env = env::get("ROCKET_ENV");

    match rocket_env.as_str() {
        "production" => rocket::build()
            .attach(cors::Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from("/www/public")),
        _ => rocket::build()
            .attach(cors::Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from(relative!("frontend/dist"))),
    }
}

#[get("/<url>")]
async fn player_route(url: &str) -> String {
    tracking::track_search_request(&url).await;

    match redis::get(&url) {
        Some(data) => {
            tracking::track_cache_hit(&url).await;
            data
        }
        None => match steam::is_vanity_url(&url) {
            true => match steam::get_steam_id_from_vanity_url(&url).await {
                Some(steam_id) => handle_new_player(&steam_id, &url).await,
                None => {
                    let msg = format!("Could not resolve steam id from vanity URL: {}", url);
                    tracking::track_error(&msg).await;
                    msg
                }
            },
            false => match steam::get_steam_id_from_non_vanity_url(&url) {
                Some(steam_id) => handle_new_player(&steam_id, &url).await,
                None => {
                    let msg = format!("Could not resolve steam id from profile url: {}", url);
                    tracking::track_error(&msg).await;
                    msg
                }
            },
        },
    }
}

async fn handle_new_player(steam_id: &str, url: &str) -> String {
    let player = create_player(steam_id, faceit::get_faceit_data(steam_id).await);
    match serde_json::to_string(&player) {
        Ok(json) => {
            redis::set(&url, &json);
            redis::expire(&url, 60 * 60 * 24); // 1 day
            json
        }
        Err(e) => {
            let msg = format!("Error serializing player: {:?}", e);
            tracking::track_error(&msg).await;
            msg
        }
    }
}

fn create_player(steam_id: &str, faceit_data: Option<faceit::FaceitResponse>) -> Player {
    let mut sites = vec![
        Site {
            url: format!("https://steamcommunity.com/profiles/{}", steam_id),
            title: "Steam".to_string(),
        },
        Site {
            url: format!("https://leetify.com/app/profile/{}", steam_id),
            title: "Leetify".to_string(),
        },
        Site {
            url: format!("https://csstats.gg/player/{}", steam_id),
            title: "CsStats".to_string(),
        },
    ];

    if let Some(data) = &faceit_data {
        sites.insert(
            1,
            Site {
                url: data.faceit_url.replace("{lang}", "en"),
                title: "Faceit".to_string(),
            },
        );
    }

    Player {
        steam_id: steam_id.to_string(),
        faceit_data,
        sites,
    }
}
