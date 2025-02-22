#[macro_use]
extern crate rocket;

use std::env;

use rocket::{
    fairing::{Fairing, Info, Kind},
    fs::{relative, FileServer},
    http::Header,
};

use rocket::{Request, Response};

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
            .attach(Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from("/www/public")),
        Err(_) => rocket::build()
            .attach(Cors)
            .mount("/player", routes![player_route, all_options])
            .mount("/", FileServer::from(relative!("frontend/dist"))),
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

/// Catches all OPTION requests in order to get the CORS related Fairing triggered.
#[options("/<_..>")]
fn all_options() {
    /* Intentionally left empty */
}

pub struct Cors;

#[rocket::async_trait]
impl Fairing for Cors {
    fn info(&self) -> Info {
        Info {
            name: "Cross-Origin-Resource-Sharing Fairing",
            kind: Kind::Response,
        }
    }

    async fn on_response<'r>(&self, _request: &'r Request<'_>, response: &mut Response<'r>) {
        response.set_header(Header::new("Access-Control-Allow-Origin", "*"));
        response.set_header(Header::new(
            "Access-Control-Allow-Methods",
            "POST, PATCH, PUT, DELETE, HEAD, OPTIONS, GET",
        ));
        response.set_header(Header::new("Access-Control-Allow-Headers", "*"));
        response.set_header(Header::new("Access-Control-Allow-Credentials", "true"));
    }
}
