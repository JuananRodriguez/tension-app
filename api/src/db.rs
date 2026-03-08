use sqlx::postgres::{PgPoolOptions};
use sqlx::PgPool;

pub async fn init_db(database_url: &str) -> Result<PgPool, sqlx::Error> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    migrate(&pool).await?;

    Ok(pool)
}

async fn migrate(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            is_admin BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS pressure_readings (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            systolic INTEGER NOT NULL,
            diastolic INTEGER NOT NULL,
            pulse INTEGER,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        "#,
    )
    .execute(pool)
    .await?;

    Ok(())
}
