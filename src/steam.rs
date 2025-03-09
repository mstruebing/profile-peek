use regex::Regex;
use reqwest::Url;

pub fn get_steam_id_from_html(lines: &str) -> Option<String> {
    let target_line = lines.lines().find(|line| line.contains("steamid"));
    let re = Regex::new(r#"^.*"steamid":"(\d*)".*$"#).unwrap();
    let Some(caps) = re.captures(target_line?) else {
        panic!("Could not extract steam id");
    };

    let steam_id = &caps[1];
    Some(steam_id.to_string())
}

pub fn get_id_from_url(url: &str) -> Option<String> {
    let parsed_url = Url::parse(url).unwrap();

    let ab = parsed_url
        .path_segments()?
        .enumerate()
        .find(|(i, _segment)| *i == 1);

    match ab {
        Some((_, segment)) => Some(segment.to_string()),
        None => None,
    }
}
