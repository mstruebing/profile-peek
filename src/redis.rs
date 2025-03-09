use redis::Commands;
use std::env;

fn connect() -> redis::Connection {
    //format - host:port
    let redis_url = env::var("REDIS_URL").expect("missing environment variable REDIS_URL");

    redis::Client::open(redis_url)
        .expect("Invalid connection URL")
        .get_connection()
        .expect("failed to connect to Redis")
}

pub fn set(key: &str, value: &str) {
    let mut con = connect();
    let _: () = con.set(key, value).expect("failed to set key");
}

pub fn get(key: &str) -> Option<String> {
    let mut con = connect();
    let value: Option<String> = con.get(key).expect("failed to get key");
    value
}

pub fn expire(key: &str, seconds: i64) {
    let mut con = connect();
    let _: () = con.expire(key, seconds).expect("failed to set expiry");
}
