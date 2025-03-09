use redis::Commands;
use std::env;

fn connect() -> redis::Connection {
    //format - host:port
    let redis_host_name =
        env::var("REDIS_HOSTNAME").expect("missing environment variable REDIS_HOSTNAME");
    let redis_password = env::var("REDIS_PASSWORD").unwrap_or_default();

    //if Redis server needs secure connection
    let uri_scheme = match env::var("IS_TLS") {
        Ok(_) => "rediss",
        Err(_) => "redis",
    };

    let redis_conn_url = format!("{}://:{}@{}", uri_scheme, redis_password, redis_host_name);

    redis::Client::open(redis_conn_url)
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
