#[macro_use]
extern crate rocket;

use std::env;

use rocket::fs::{relative, FileServer};
use serde::Serialize;

use regex::Regex;

#[derive(Serialize)]
struct SteamId {
    steam_id: String,
}

#[get("/<url>")]
async fn player_route(url: &str) -> String {
    let resp = reqwest::get(url).await.unwrap().text().await;

    match resp {
        Ok(resp) => match extract_steam_id(&resp) {
            Some(steam_id) => {
                let steam_id = SteamId { steam_id };

                let json = serde_json::to_string(&steam_id);
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
            .mount("/player", routes![player_route])
            .mount("/", FileServer::from("/www/public")),
        Err(_) => rocket::build()
            .mount("/player", routes![player_route])
            .mount(
                "/",
                FileServer::from(relative!("frontend/csportal-player-finder/dist")),
            ),
    }
}

fn extract_steam_id(lines: &str) -> Option<String> {
    let target_line = lines.lines().find(|line| line.contains("steamid"));
    let re = Regex::new(r#"^.*"steamid":"(\d*)".*$"#).unwrap();
    let Some(caps) = re.captures(target_line?) else {
        panic!("Could not extract steam id");
    };

    let steam_id = &caps[1];
    Some(steam_id.to_string())
}
