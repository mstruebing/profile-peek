use reqwest::Url;
use serde::Serialize;

use crate::env;

#[derive(Serialize)]
pub struct VacBanInfo {
    is_banned: bool,
    ban_count: u32,
    days_since_last_ban: Option<u32>,
}

/// if a url is a vanity url
/// vanity url is a url that looks like this: https://steamcommunity.com/id/username
pub fn is_vanity_url(url: &str) -> bool {
    let parsed_url = Url::parse(url).unwrap();
    let segments: Vec<&str> = parsed_url.path_segments().unwrap().collect();
    segments.len() >= 2 && segments[0] == "id"
}

pub async fn get_steam_id_from_vanity_url(url: &str) -> Option<String> {
    let username = get_username_from_vanity_url(url);

    if let Some(username) = username {
        let api_url = format!(
            "https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/?key={}&vanityurl={}",
            env::get("STEAM_API_KEY"),
            username
        );
        let response = reqwest::get(&api_url).await.ok()?;

        let json: serde_json::Value = response.json().await.ok()?;
        if let Some(steam_id) = json["response"]["steamid"].as_str() {
            return Some(steam_id.to_string());
        }
    }

    None
}

pub fn get_steam_id_from_non_vanity_url(url: &str) -> Option<String> {
    let parsed_url = Url::parse(url).unwrap();
    let segments: Vec<&str> = parsed_url.path_segments().unwrap().collect();

    if segments.len() < 2 || segments[0] != "profiles" {
        None
    } else {
        Some(segments[1].to_string())
    }
}

fn get_username_from_vanity_url(url: &str) -> Option<String> {
    let parsed_url = Url::parse(url).unwrap();
    let segments: Vec<&str> = parsed_url.path_segments().unwrap().collect();

    if segments.len() < 2 || segments[0] != "id" {
        None
    } else {
        Some(segments[1].to_string())
    }
}

pub fn normalize_url(url: &str) -> Result<String, String> {
    let mut parsed_url = Url::parse(url).unwrap();
    parsed_url.set_query(None);
    parsed_url.set_fragment(None);

    let segments: Vec<&str> = parsed_url.path_segments().unwrap().collect();
    if segments.len() >= 2 && (segments[0] == "id" || segments[0] == "profiles") {
        let base_path = format!("{}/{}", segments[0], segments[1]);
        parsed_url.set_path(&base_path);
        return Ok(parsed_url.to_string());
    }

    Err("Invalid URL format".to_string())
}

/// Fetch CS2 hours for a given Steam ID
/// Returns the number of hours played in CS2, or None if not found/error
pub async fn get_cs2_hours(steam_id: &str) -> Option<u32> {
    let api_url = format!(
        "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key={}&steamid={}&include_appinfo=1&include_played_free_games=1",
        env::get("STEAM_API_KEY"),
        steam_id
    );

    let response = reqwest::get(&api_url).await.ok()?;
    let json: serde_json::Value = response.json().await.ok()?;

    // CS2's app ID is 730
    if let Some(games) = json["response"]["games"].as_array() {
        for game in games {
            if let Some(app_id) = game["appid"].as_u64() {
                if app_id == 730 {
                    // Convert minutes to hours (playtime_forever is in minutes)
                    if let Some(minutes) = game["playtime_forever"].as_u64() {
                        return Some((minutes / 60) as u32);
                    }
                }
            }
        }
    }

    None
}

/// Fetch account creation date for a given Steam ID
/// Returns the Unix timestamp when the account was created, or None if not found/error
pub async fn get_account_creation_date(steam_id: &str) -> Option<i64> {
    let api_url = format!(
        "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key={}&steamids={}",
        env::get("STEAM_API_KEY"),
        steam_id
    );

    let response = reqwest::get(&api_url).await.ok()?;
    let json: serde_json::Value = response.json().await.ok()?;

    if let Some(players) = json["response"]["players"].as_array() {
        if let Some(player) = players.first() {
            if let Some(timecreated) = player["timecreated"].as_i64() {
                return Some(timecreated);
            }
        }
    }

    None
}

/// Fetch VAC ban information for a given Steam ID
/// Returns a tuple of (VAC banned, number of VAC bans, days since last ban)
pub async fn get_vac_ban_info(steam_id: &str) -> Option<VacBanInfo> {
    let api_url = format!(
        "https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key={}&steamids={}",
        env::get("STEAM_API_KEY"),
        steam_id
    );

    let response = reqwest::get(&api_url).await.ok()?;
    let json: serde_json::Value = response.json().await.ok()?;

    if let Some(players) = json["players"].as_array() {
        if let Some(player) = players.first() {
            let vac_banned = player["VACBanned"].as_bool().unwrap_or(false);
            let number_of_vac_bans = player["NumberOfVACBans"].as_u64().unwrap_or(0) as u32;

            // DaysSinceLastBan is -1 if no bans, otherwise it's the number of days
            let days_since_last_ban = if let Some(days) = player["DaysSinceLastBan"].as_i64() {
                if days >= 0 {
                    Some(days as u32)
                } else {
                    None
                }
            } else {
                None
            };

            return Some(VacBanInfo {
                is_banned: vac_banned,
                ban_count: number_of_vac_bans,
                days_since_last_ban,
            });
        }
    }

    None
}
