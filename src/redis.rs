use r2d2;
use r2d2_redis::RedisConnectionManager;
use redis::AsyncCommands;
use std::env;
use once_cell::sync::Lazy;

type Pool = r2d2::Pool<RedisConnectionManager>;
type PooledConnection = r2d2::PooledConnection<RedisConnectionManager>;

static POOL: Lazy<Pool> = Lazy::new(|| {
    let redis_url = env::var("REDIS_URL").expect("missing environment variable REDIS_URL");
    let manager = RedisConnectionManager::new(redis_url).expect("Failed to create Redis connection manager");
    r2d2::Pool::builder()
        .max_size(15) // Adjust this based on your needs
        .build(manager)
        .expect("Failed to create Redis connection pool")
});

pub async fn set(key: &str, value: &str) {
    let conn = POOL.get().expect("Failed to get Redis connection from pool");
    let _: () = redis::cmd("SET")
        .arg(key)
        .arg(value)
        .query_async(&mut *conn)
        .await
        .expect("failed to set key");
}

pub async fn get(key: &str) -> Option<String> {
    let conn = POOL.get().expect("Failed to get Redis connection from pool");
    redis::cmd("GET")
        .arg(key)
        .query_async(&mut *conn)
        .await
        .expect("failed to get key")
}

pub async fn expire(key: &str, seconds: i64) {
    let conn = POOL.get().expect("Failed to get Redis connection from pool");
    let _: () = redis::cmd("EXPIRE")
        .arg(key)
        .arg(seconds)
        .query_async(&mut *conn)
        .await
        .expect("failed to set expiry");
}
