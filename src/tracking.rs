use reqwest::Client;
use serde_json::json;
use std::collections::HashMap;

use crate::env;

async fn send_event(event_name: &str, props: HashMap<String, String>) {
    let client = Client::new();
    let body = json!({
        "name": event_name,
        "url": "https://profile-peek.com/backend",
        "domain": "profile-peek.com",
        "props": props,
    });

    let response = client
        .post(env::get("TRACKING_URL"))
        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36")
        .header("X-Forwarded-For", "127.0.0.1")
        .json(&body)
        .send()
        .await;

    match response {
        Ok(res) if res.status().is_success() => (),
        Ok(res) => eprintln!(
            "Failed to track event: {} - {}",
            res.status(),
            res.text().await.unwrap_or_default()
        ),
        Err(err) => eprintln!("Error sending event: {}", err),
    }
}

pub async fn track_cache_hit(url: &str) {
    let mut props = HashMap::new();
    props.insert("url".to_string(), url.to_string());

    send_event("cache_hit", props).await;
}

pub async fn track_search_request(url: &str) {
    let mut props = HashMap::new();
    props.insert("url".to_string(), url.to_string());

    send_event("search_request", props).await;
}

pub async fn track_error(msg: &str) {
    let mut props = HashMap::new();
    props.insert("msg".to_string(), msg.to_string());

    send_event("error", props).await;
}
