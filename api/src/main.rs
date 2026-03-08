mod db;

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{delete, get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, SqlitePool};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

#[derive(Clone)]
struct AppState {
    db: SqlitePool,
}

#[derive(Deserialize)]
struct CreateUserRequest {
    name: String,
}

#[derive(Serialize, FromRow)]
struct UserResponse {
    id: i64,
    name: String,
    created_at: String,
}

#[derive(Deserialize)]
struct CreateReadingRequest {
    user_id: i64,
    systolic: i32,
    diastolic: i32,
    pulse: Option<i32>,
    notes: Option<String>,
}

#[derive(Serialize, FromRow)]
struct ReadingResponse {
    id: i64,
    user_id: i64,
    systolic: i32,
    diastolic: i32,
    pulse: Option<i32>,
    notes: Option<String>,
    created_at: String,
}

#[tokio::main]
async fn main() {
    let db_path = std::env::var("DATABASE_PATH").unwrap_or_else(|_| "tension.db".to_string());

    let db = db::init_db(&db_path)
        .await
        .expect("Failed to initialize database");

    let state = AppState { db };

    let app = Router::new()
        .route("/health", get(health))
        .route("/users", post(create_user))
        .route("/users", get(list_users))
        .route("/users/:id", delete(delete_user))
        .route("/readings", post(create_reading))
        .route("/readings/:user_id", get(list_readings))
        .route("/readings/:id/delete", delete(delete_reading))
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));

    println!("🚀 API running on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind address");

    axum::serve(listener, app)
        .await
        .expect("Server error");
}

async fn health() -> impl IntoResponse {
    (StatusCode::OK, Json(serde_json::json!({ "status": "ok" })))
}

async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> impl IntoResponse {
    let insert_result = sqlx::query("INSERT INTO users (name) VALUES (?)")
        .bind(&payload.name)
        .execute(&state.db)
        .await;

    match insert_result {
        Ok(result) => {
            let id = result.last_insert_rowid();
            let user = sqlx::query_as::<_, UserResponse>(
                "SELECT id, name, created_at FROM users WHERE id = ?"
            )
            .bind(id)
            .fetch_one(&state.db)
            .await;

            match user {
                Ok(u) => (StatusCode::CREATED, Json(serde_json::json!(u))).into_response(),
                Err(e) => {
                    eprintln!("Error fetching user after insert: {:?}", e);
                    (StatusCode::INTERNAL_SERVER_ERROR, format!("Error fetching user: {}", e)).into_response()
                }
            }
        }
        Err(e) => {
            eprintln!("Error inserting user: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error creating user: {}", e)).into_response()
        }
    }
}

async fn list_users(
    State(state): State<AppState>,
) -> impl IntoResponse {
    let users = sqlx::query_as::<_, UserResponse>(
        "SELECT id, name, created_at FROM users ORDER BY created_at DESC"
    )
    .fetch_all(&state.db)
    .await;

    match users {
        Ok(u) => (StatusCode::OK, Json(u)).into_response(),
        Err(e) => {
            eprintln!("Error fetching users: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error fetching users: {}", e)).into_response()
        }
    }
}

async fn create_reading(
    State(state): State<AppState>,
    Json(payload): Json<CreateReadingRequest>,
) -> impl IntoResponse {
    let result = sqlx::query(
        "INSERT INTO pressure_readings (user_id, systolic, diastolic, pulse, notes) VALUES (?, ?, ?, ?, ?)"
    )
    .bind(payload.user_id)
    .bind(payload.systolic)
    .bind(payload.diastolic)
    .bind(payload.pulse)
    .bind(payload.notes)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => (StatusCode::CREATED, Json(serde_json::json!({ "created": true }))).into_response(),
        Err(e) => {
            eprintln!("Error creating reading: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error creating reading: {}", e)).into_response()
        }
    }
}

async fn list_readings(
    Path(user_id): Path<i64>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let readings = sqlx::query_as::<_, ReadingResponse>(
        "SELECT id, user_id, systolic, diastolic, pulse, notes, created_at 
         FROM pressure_readings 
         WHERE user_id = ? 
         ORDER BY created_at DESC"
    )
    .bind(user_id)
    .fetch_all(&state.db)
    .await;

    match readings {
        Ok(r) => (StatusCode::OK, Json(r)).into_response(),
        Err(e) => {
            eprintln!("Error fetching readings: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error fetching readings: {}", e)).into_response()
        }
    }
}

async fn delete_user(
    Path(id): Path<i64>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let result = sqlx::query("DELETE FROM users WHERE id = ?")
        .bind(id)
        .execute(&state.db)
        .await;

    match result {
        Ok(_) => (StatusCode::OK, Json(serde_json::json!({ "deleted": true }))).into_response(),
        Err(e) => {
            eprintln!("Error deleting user: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error deleting user: {}", e)).into_response()
        }
    }
}

async fn delete_reading(
    Path(id): Path<i64>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let result = sqlx::query("DELETE FROM pressure_readings WHERE id = ?")
        .bind(id)
        .execute(&state.db)
        .await;

    match result {
        Ok(_) => (StatusCode::OK, Json(serde_json::json!({ "deleted": true }))).into_response(),
        Err(e) => {
            eprintln!("Error deleting reading: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error deleting reading: {}", e)).into_response()
        }
    }
}