use crate::env;
use r2d2::Pool;
use r2d2_redis::redis::{parse_redis_url, Commands};
use r2d2_redis::RedisConnectionManager;

type RedisPool = Pool<RedisConnectionManager>;

fn create_pool() -> RedisPool {
    let redis_url = env::get("REDIS_URL");
    let manager = RedisConnectionManager::new(parse_redis_url(&redis_url).unwrap())
        .expect("Invalid connection URL");

    Pool::builder()
        .build(manager)
        .expect("Failed to create pool")
}

lazy_static::lazy_static! {
    static ref POOL: RedisPool = create_pool();
}

pub fn set(key: &str, value: &str) {
    let pool = POOL.clone();
    let mut con = pool.get().expect("Failed to get connection from pool");
    let _: () = con.set(key, value).expect("failed to set key");
}

pub fn get(key: &str) -> Option<String> {
    let pool = POOL.clone();
    let mut con = pool.get().expect("Failed to get connection from pool");
    let value: Option<String> = con.get(key).expect("failed to get key");
    value
}

pub fn expire(key: &str, seconds: usize) {
    let pool = POOL.clone();
    let mut con = pool.get().expect("Failed to get connection from pool");
    let _: () = con.expire(key, seconds).expect("failed to set expiry");
}
