#[macro_use]
extern crate rocket;

use rocket::fs::{relative, FileServer};
use serde::Serialize;
use std::env;
use rocket::response::content::Json;
use rocket::http::Status;
use rocket::response::status;
use thiserror::Error;

mod cors;
mod redis;
mod steam;

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

#[derive(Error, Debug)]
enum PlayerError {
    #[error("Failed to fetch URL: {0}")]
    FetchError(#[from] reqwest::Error),
    #[error("Failed to serialize JSON: {0}")]
    JsonError(#[from] serde_json::Error),
    #[error("Could not extract Steam ID from response")]
    SteamIdNotFound,
}

type PlayerResult<T> = Result<T, PlayerError>;

#[get("/<url>")]
async fn player_route(url: &str) -> Result<Json<String>, status::Custom<String>> {
    let result = match redis::get(url).await {
        Some(steam_id) => get_player_json(&steam_id).await,
        None => {
            let resp = reqwest::get(url).await?.text().await?;
            let steam_id = steam::get_id(&resp).ok_or(PlayerError::SteamIdNotFound)?;
            
            let json = get_player_json(&steam_id).await?;
            
            // Cache the result
            redis::set(url, &steam_id).await;
            redis::expire(url, 60 * 60 * 24).await;
            
            Ok(json)
        }
    };

    match result {
        Ok(json) => Ok(Json(json)),
        Err(e) => {
            eprintln!("Error processing request: {}", e);
            Err(status::Custom(
                Status::InternalServerError,
                e.to_string()
            ))
        }
    }
}

#[launch]
fn rocket() -> _ {
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

/// Catches all OPTION requests in order to get the CORS related Fairing triggered.
#[options("/<_..>")]
fn all_options() {
    /* Intentionally left empty */
}

async fn get_player_json(steam_id: &str) -> PlayerResult<String> {
    let player = create_player(steam_id);
    Ok(serde_json::to_string(&player)?)
}


fn create_player(steam_id: &str) -> Player {
    Player {
        steam_id: steam_id.to_string(),
        sites: create_sites(steam_id),
    }
}

fn create_sites(steam_id: &str) -> Vec<Site> {
    vec![
        Site {
            url: format!("https://leetify.com/app/profile/{}", steam_id),
            title: "Leetify".to_string(),
        },
        Site {
            url: format!("https://csstats.gg/player/{}", steam_id),
            title: "csstats".to_string(),
        },
        Site {
            url: format!("https://faceitfinder.com/profile/{}", steam_id),
            title: "Faceitfinder".to_string(),
        },
        Site {
            url: format!("https://www.skinpock.com/inventory/{}", steam_id),
            title: "skinpock".to_string(),
        },
    ]
}
