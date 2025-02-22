use regex::Regex;

pub fn get_id(lines: &str) -> Option<String> {
    let target_line = lines.lines().find(|line| line.contains("steamid"));
    let re = Regex::new(r#"^.*"steamid":"(\d*)".*$"#).unwrap();
    let Some(caps) = re.captures(target_line?) else {
        panic!("Could not extract steam id");
    };

    let steam_id = &caps[1];
    Some(steam_id.to_string())
}
