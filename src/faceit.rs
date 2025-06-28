use chrono::DateTime;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION};
use serde::{Deserialize, Serialize};

use crate::env;

#[derive(Deserialize, Serialize)]
pub struct FaceitData {
    pub account_created: i64,
    pub adr: f32,
    pub avatar: Option<String>,
    pub country: String,
    pub deaths: u16,
    pub double_kills: u16,
    pub elo: u16,
    pub headshot_percentage: f32,
    pub headshots: u16,
    pub kd_ratio: f32,
    pub kills: u16,
    pub kr_ratio: f32,
    pub level: u8,
    pub losses: u8,
    pub nickname: String,
    pub penta_kills: u16,
    pub quadro_kills: u16,
    pub triple_kills: u16,
    pub win_rate: u8,
    pub wins: u8,
}

#[derive(Deserialize, Serialize)]
pub struct FaceitPlayerDetailsAPIResponse {
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
    // If the structure is unknown
    pub infractions: Option<serde_json::Value>,
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

#[derive(Serialize, Deserialize, Debug)]
pub struct MatchStats {
    #[serde(rename = "ADR")]
    pub adr: String,
    #[serde(rename = "Assists")]
    pub assists: String,
    #[serde(rename = "Best Of")]
    pub best_of: String,
    #[serde(rename = "Competition Id")]
    pub competition_id: String,
    #[serde(rename = "Created At")]
    pub created_at: String,
    #[serde(rename = "Deaths")]
    pub deaths: String,
    #[serde(rename = "Double Kills")]
    pub double_kills: String,
    #[serde(rename = "Final Score")]
    pub final_score: String,
    #[serde(rename = "First Half Score")]
    pub first_half_score: String,
    #[serde(rename = "Game")]
    pub game: String,
    #[serde(rename = "Game Mode")]
    pub game_mode: String,
    #[serde(rename = "Headshots")]
    pub headshots: String,
    #[serde(rename = "Headshots %")]
    pub headshot_percentage: String,
    #[serde(rename = "K/D Ratio")]
    pub kd_ratio: String,
    #[serde(rename = "K/R Ratio")]
    pub kr_ratio: String,
    #[serde(rename = "Kills")]
    pub kills: String,
    #[serde(rename = "MVPs")]
    pub mvps: String,
    #[serde(rename = "Map")]
    pub map: String,
    #[serde(rename = "Match Finished At")]
    pub match_finished_at: u64,
    #[serde(rename = "Match Id")]
    pub match_id: String,
    #[serde(rename = "Match Round")]
    pub match_round: String,
    #[serde(rename = "Nickname")]
    pub nickname: String,
    #[serde(rename = "Overtime score")]
    pub overtime_score: String,
    #[serde(rename = "Penta Kills")]
    pub penta_kills: String,
    #[serde(rename = "Player Id")]
    pub player_id: String,
    #[serde(rename = "Quadro Kills")]
    pub quadro_kills: String,
    #[serde(rename = "Region")]
    pub region: String,
    #[serde(rename = "Result")]
    pub result: String,
    #[serde(rename = "Rounds")]
    pub rounds: String,
    #[serde(rename = "Score")]
    pub score: String,
    #[serde(rename = "Second Half Score")]
    pub second_half_score: String,
    #[serde(rename = "Team")]
    pub team: String,
    #[serde(rename = "Triple Kills")]
    pub triple_kills: String,
    #[serde(rename = "Updated At")]
    pub updated_at: String,
    #[serde(rename = "Winner")]
    pub winner: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct MatchItem {
    pub stats: MatchStats,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct PlayerLastMatchesResponse {
    pub start: u64,
    pub end: u64,
    pub items: Vec<MatchItem>,
}

pub async fn get_player_details(steam_id: &str) -> Option<FaceitPlayerDetailsAPIResponse> {
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
                match response.json::<FaceitPlayerDetailsAPIResponse>().await {
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

pub async fn get_player_last_matches(player_id: &str) -> Option<PlayerLastMatchesResponse> {
    let api_url = format!(
        "https://open.faceit.com/data/v4/players/{}/games/cs2/stats",
        player_id
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
                match response.json::<PlayerLastMatchesResponse>().await {
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

pub fn from_api(
    data: Option<FaceitPlayerDetailsAPIResponse>,
    last_matches: Option<PlayerLastMatchesResponse>,
) -> Option<FaceitData> {
    match data {
        Some(d) => {
            let (level, elo) = match d.games.cs2 {
                Some(game) => (game.skill_level, game.faceit_elo),
                None => (0, 0),
            };

            let account_created = match DateTime::parse_from_rfc3339(&d.activated_at) {
                Ok(parsed_date) => parsed_date.timestamp(),
                Err(_) => 0, // Default to 0 if parsing fails
            };

            // Calculate aggregated stats from last matches
            let (
                adr,
                wins,
                losses,
                win_rate,
                kills,
                deaths,
                kd_ratio,
                kr_ratio,
                headshots,
                headshot_percentage,
                double_kills,
                triple_kills,
                quadro_kills,
                penta_kills,
            ) = if let Some(matches) = last_matches {
                let mut total_adr = 0.0;
                let mut total_wins = 0;
                let mut total_losses = 0;
                let mut total_kills = 0;
                let mut total_deaths = 0;
                let mut total_kr_ratio = 0.0;
                let mut total_headshots = 0;
                let mut total_double_kills = 0;
                let mut total_triple_kills = 0;
                let mut total_quadro_kills = 0;
                let mut total_penta_kills = 0;
                let mut match_count = 0;

                for match_item in matches.items {
                    let stats = match_item.stats;
                    match_count += 1;

                    // Parse ADR (Average Damage per Round)
                    if let Ok(adr_val) = stats.adr.parse::<f32>() {
                        total_adr += adr_val;
                    }

                    // Count wins/losses
                    if stats.result == "1" {
                        total_wins += 1;
                    } else {
                        total_losses += 1;
                    }

                    // Parse kills and deaths
                    if let Ok(kills_val) = stats.kills.parse::<u16>() {
                        total_kills += kills_val;
                    }
                    if let Ok(deaths_val) = stats.deaths.parse::<u16>() {
                        total_deaths += deaths_val;
                    }

                    // Parse K/R ratio
                    if let Ok(kr_val) = stats.kr_ratio.parse::<f32>() {
                        total_kr_ratio += kr_val;
                    }

                    // Parse headshots
                    if let Ok(headshots_val) = stats.headshots.parse::<u16>() {
                        total_headshots += headshots_val;
                    }

                    // Parse multi-kills
                    if let Ok(double_val) = stats.double_kills.parse::<u16>() {
                        total_double_kills += double_val;
                    }
                    if let Ok(triple_val) = stats.triple_kills.parse::<u16>() {
                        total_triple_kills += triple_val;
                    }
                    if let Ok(quadro_val) = stats.quadro_kills.parse::<u16>() {
                        total_quadro_kills += quadro_val;
                    }
                    if let Ok(penta_val) = stats.penta_kills.parse::<u16>() {
                        total_penta_kills += penta_val;
                    }
                }

                // Calculate averages and ratios
                let avg_adr = if match_count > 0 {
                    total_adr / match_count as f32
                } else {
                    0.0
                };
                let win_rate = if (total_wins + total_losses) > 0 {
                    ((total_wins as f32 / (total_wins + total_losses) as f32) * 100.0).round() as u8
                } else {
                    0 as u8
                };
                let kd_ratio = if total_deaths > 0 {
                    total_kills as f32 / total_deaths as f32
                } else {
                    0.0
                };
                let avg_kr_ratio = if match_count > 0 {
                    total_kr_ratio / match_count as f32
                } else {
                    0.0
                };
                let headshot_percentage = if total_kills > 0 {
                    (total_headshots as f32 / total_kills as f32) * 100.0
                } else {
                    0.0
                };

                (
                    avg_adr,
                    total_wins,
                    total_losses,
                    win_rate,
                    total_kills,
                    total_deaths,
                    kd_ratio,
                    avg_kr_ratio,
                    total_headshots,
                    headshot_percentage,
                    total_double_kills,
                    total_triple_kills,
                    total_quadro_kills,
                    total_penta_kills,
                )
            } else {
                // Default values when no match data is available
                (0.0, 0, 0, 0, 0, 0, 0.0, 0.0, 0, 0.0, 0, 0, 0, 0)
            };

            Some(FaceitData {
                account_created,
                adr,
                avatar: d.avatar,
                country: d.country,
                deaths,
                double_kills,
                elo,
                headshots,
                headshot_percentage,
                kd_ratio,
                kills,
                kr_ratio,
                level,
                losses,
                nickname: d.nickname,
                penta_kills,
                quadro_kills,
                triple_kills,
                win_rate,
                wins,
            })
        }
        _ => None,
    }
}
