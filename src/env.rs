static REQUIRED_ENV_VARS: &[&str] = &["REDIS_URL", "STEAM_API_KEY", "FACEIT_API_KEY", "ROCKET_ENV"];

/// Ensures that the required environment variables are set in the .env file.
/// If any of the required variables are not set, it will panic with an error message.
pub fn ensure_set() {
    dotenv::dotenv().ok();

    for &var in REQUIRED_ENV_VARS {
        if dotenv::var(var).is_err() {
            panic!("{} is not set in .env file", var);
        }
    }
}

pub fn get(key: &str) -> String {
    dotenv::var(key).unwrap_or_else(|_| panic!("Environment variable {} is not set", key))
}
