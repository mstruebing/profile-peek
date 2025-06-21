#[macro_use]
extern crate rocket;

use rocket::fs::{relative, FileServer, NamedFile};
use serde::Serialize;

use rocket::fairing::{Fairing, Info, Kind};
use rocket::http::Header;
use rocket::{Request, Response};

mod cors;
mod env;
mod faceit;
mod redis;
mod steam;
mod tracking;

pub struct CacheFairing;

#[derive(Serialize)]
struct Player {
    steam_id: String,
    faceit_data: Option<faceit::FaceitData>,
    sites: Vec<Site>,
}

#[derive(Serialize)]
struct Site {
    url: String,
    title: String,
}

#[rocket::async_trait]
impl Fairing for CacheFairing {
    fn info(&self) -> Info {
        Info {
            name: "Add Cache-Control Header",
            kind: Kind::Response,
        }
    }

    async fn on_response<'r>(&self, request: &'r Request<'_>, response: &mut Response<'r>) {
        // Add cache headers except for the player route
        if !request.uri().path().starts_with("/player") {
            response.set_header(Header::new("Cache-Control", "public, max-age=31536000"));
        }
    }
}

/// Catches all OPTION requests in order to get the CORS related Fairing triggered.
#[options("/<_..>")]
fn all_options() {
    /* Intentionally left empty */
}

#[catch(default)]
async fn default_catch(_req: &Request<'_>) -> Option<NamedFile> {
    match env::get("ROCKET_ENV").as_str() {
        "production" => NamedFile::open("/www/public/index.html").await.ok(),
        _ => NamedFile::open(relative!("frontend/dist/index.html"))
            .await
            .ok(),
    }
}

#[launch]
fn rocket() -> _ {
    env::ensure_set();
    let rocket_env = env::get("ROCKET_ENV");

    match rocket_env.as_str() {
        "production" => rocket::build()
            .attach(cors::Cors)
            .attach(CacheFairing)
            .mount("/api/v1/player", routes![player_route, all_options])
            .mount("/player", routes![old_player_route, all_options])
            .mount("/", FileServer::from("/www/public"))
            .register("/", catchers![default_catch]),
        _ => rocket::build()
            .attach(cors::Cors)
            .attach(CacheFairing)
            .mount("/api/v1/player", routes![player_route, all_options])
            .mount("/player", routes![old_player_route, all_options])
            .mount("/", FileServer::from(relative!("frontend/dist")))
            .register("/", catchers![default_catch]),
    }
}

#[get("/<url>")]
async fn player_route(url: &str) -> Result<String, String> {
    tracking::track_search_request(&url).await;
    let normalized_url = steam::normalize_url(url)?;

    match redis::get(&normalized_url) {
        Some(data) => {
            tracking::track_cache_hit(&normalized_url).await;
            Ok(data)
        }
        None => match steam::is_vanity_url(&normalized_url) {
            true => match steam::get_steam_id_from_vanity_url(&normalized_url).await {
                Some(steam_id) => Ok(handle_new_player(&steam_id, &normalized_url).await),
                None => {
                    let msg = format!(
                        "Could not resolve steam id from vanity URL: {}",
                        normalized_url
                    );
                    tracking::track_error(&msg).await;
                    Err(msg)
                }
            },
            false => match steam::get_steam_id_from_non_vanity_url(&normalized_url) {
                Some(steam_id) => Ok(handle_new_player(&steam_id, &normalized_url).await),
                None => {
                    let msg = format!(
                        "Could not resolve steam id from profile url: {}",
                        normalized_url
                    );
                    tracking::track_error(&msg).await;
                    Err(msg)
                }
            },
        },
    }
}

#[get("/<url>")]
async fn old_player_route(url: &str) -> Result<String, String> {
    tracking::track_search_request(&url).await;
    let normalized_url = steam::normalize_url(url)?;

    match redis::get(&normalized_url) {
        Some(data) => {
            tracking::track_cache_hit(&normalized_url).await;
            Ok(data)
        }
        None => match steam::is_vanity_url(&normalized_url) {
            true => match steam::get_steam_id_from_vanity_url(&normalized_url).await {
                Some(steam_id) => Ok(handle_new_player(&steam_id, &normalized_url).await),
                None => {
                    let msg = format!(
                        "Could not resolve steam id from vanity URL: {}",
                        normalized_url
                    );
                    tracking::track_error(&msg).await;
                    Err(msg)
                }
            },
            false => match steam::get_steam_id_from_non_vanity_url(&normalized_url) {
                Some(steam_id) => Ok(handle_new_player(&steam_id, &normalized_url).await),
                None => {
                    let msg = format!(
                        "Could not resolve steam id from profile url: {}",
                        normalized_url
                    );
                    tracking::track_error(&msg).await;
                    Err(msg)
                }
            },
        },
    }
}

async fn handle_new_player(steam_id: &str, url: &str) -> String {
    let faceit_data = faceit::get_player_details(steam_id).await;

    // Only get last matches if we have valid faceit data
    let last_matches = if let Some(ref player_details) = faceit_data {
        faceit::get_player_last_matches(&player_details.player_id).await
    } else {
        None
    };

    let player = create_player(steam_id, faceit_data, last_matches);
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

fn create_player(
    steam_id: &str,
    faceit_data: Option<faceit::FaceitPlayerDetailsAPIResponse>,
    last_matches: Option<faceit::PlayerLastMatchesResponse>,
) -> Player {
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
        faceit_data: faceit::from_api(faceit_data, last_matches),
        sites,
    }
}
