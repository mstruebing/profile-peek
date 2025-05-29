use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION};
use serde::{Deserialize, Serialize};

use crate::env;

#[derive(Deserialize, Serialize)]
pub struct FaceitResponse {
    pub player_id: String,
    pub nickname: String,
    pub avatar: Option<String>,
    pub country: String,
    pub cover_image: Option<String>,
    pub platforms: Platforms,
    pub games: Games,
    pub settings: Settings,
    pub friends_ids: Vec<String>,
    pub new_steam_id: Option<String>,
    pub steam_id_64: String,
    pub steam_nickname: String,
    pub memberships: Vec<String>,
    pub faceit_url: String,
    pub membership_type: Option<String>,
    pub cover_featured_image: Option<String>,
    pub infractions: Option<serde_json::Value>, // If the structure is unknown
    pub verified: bool,
    pub activated_at: String,
}

#[derive(Deserialize, Serialize)]
pub struct Platforms {
    pub steam: String,
}

#[derive(Deserialize, Serialize)]
pub struct Games {
    pub cs2: Option<GameDetails>,
    pub csgo: Option<GameDetails>,
}

#[derive(Deserialize, Serialize)]
pub struct GameDetails {
    pub region: String,
    pub game_player_id: String,
    pub skill_level: u8,
    pub faceit_elo: u16,
    pub game_player_name: String,
    pub skill_level_label: Option<String>,
    pub regions: Option<serde_json::Value>, // If the structure is unknown
    pub game_profile_id: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Settings {
    pub language: String,
}

pub async fn get_faceit_data(steam_id: &str) -> Option<FaceitResponse> {
    let api_url = format!(
        "https://open.faceit.com/data/v4/players?game=csgo&game_player_id={}",
        steam_id
    );

    let mut headers = HeaderMap::new();
    headers.insert(
        AUTHORIZATION,
        HeaderValue::from_str(&format!("Bearer {}", env::get("FACEIT_API_KEY"))).ok()?,
    );

    let client = reqwest::Client::new();

    match client.get(&api_url).headers(headers).send().await {
        Ok(response) => {
            if response.status().is_success() {
                match response.json::<FaceitResponse>().await {
                    Ok(data) => Some(data),
                    Err(_) => None,
                }
            } else {
                None
            }
        }
        Err(_) => None,
    }
}
