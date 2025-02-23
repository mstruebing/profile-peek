#[macro_use]
extern crate rocket;

use rocket::fs::{relative, FileServer};
use serde::Serialize;
use std::env;

mod cors;
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

#[get("/<url>")]
async fn player_route(url: &str) -> String {
    let resp = reqwest::get(url).await.unwrap().text().await;

    match resp {
        Ok(resp) => match steam::get_id(&resp) {
            Some(steam_id) => {
                let player = Player {
                    steam_id: steam_id.clone().to_string(),
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
                    ],
                };

                let json = serde_json::to_string(&player);
                match json {
                    Ok(json) => {
                        format!("{}", json)
                    }
                    Err(e) => {
                        println!("error: {:?}", e);
                        format!("Something went wrong")
                    }
                }
            }
            None => {
                format!("Could not extract steam id")
            }
        },
        Err(e) => {
            println!("error: {:?}", e);
            format!("Something went wrong")
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
