#[macro_use]
extern crate rocket;

use rocket::fs::{relative, FileServer};
use serde::Serialize;
use std::env;

mod cors;
mod redis;
mod steam;
mod tracking;

#[derive(Serialize)]
struct Player {
    steam_id: String,
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
    // make sure the domain is defined when starting the server
    tracking::get_domain();

    let rocket_env = env::var("ROCKET_ENV");
    match rocket_env {
        Ok(_) => rocket::build()
            .attach(cors::Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from("/www/public")),
        Err(_) => rocket::build()
            .attach(cors::Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from(relative!("frontend/dist"))),
    }
}

#[get("/<url>")]
async fn player_route(url: &str) -> String {
    tracking::track_search_request(&url).await;

    match steam::get_id_from_url(url) {
        Some(id) => match redis::get(&id) {
            Some(steam_id) => {
                tracking::track_cache_hit(&steam_id, &url).await;
                handle_cached_player(&steam_id, url)
            }
            None => handle_new_player(&id, url).await,
        },
        None => format!("Could not extract steam id from url"),
    }
}

fn handle_cached_player(steam_id: &str, url: &str) -> String {
    let player = create_player(steam_id, url);
    match serde_json::to_string(&player) {
        Ok(json) => format!("{}", json),
        Err(e) => {
            println!("error: {:?}", e);
            format!("Something went wrong")
        }
    }
}

async fn handle_new_player(id: &str, url: &str) -> String {
    match reqwest::get(url).await.unwrap().text().await {
        Ok(resp) => match steam::get_steam_id_from_html(&resp) {
            Some(steam_id) => {
                let player = create_player(&steam_id, url);
                match serde_json::to_string(&player) {
                    Ok(json) => {
                        redis::set(id, &steam_id);
                        redis::expire(id, 60 * 60 * 24);
                        format!("{}", json)
                    }
                    Err(e) => {
                        tracking::track_error(
                            format!("Error serializing player: {:?}", e).as_str(),
                        )
                        .await;
                        format!("Something went wrong")
                    }
                }
            }
            None => {
                tracking::track_error(&format!("Could not extract steam id from html: {:?}", url))
                    .await;
                format!("Could not extract steam id from html")
            }
        },
        Err(e) => {
            tracking::track_error(format!("Error fetching url({:?}): {:?}", url, e).as_str()).await;
            format!("Something went wrong")
        }
    }
}

fn create_player(steam_id: &str, url: &str) -> Player {
    Player {
        steam_id: steam_id.to_string(),
        sites: vec![
            Site {
                url: url.to_string(),
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
        ],
    }
}
