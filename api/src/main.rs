mod db;

use axum::{
    extract::{Path, State},
    http::{header, StatusCode},
    response::IntoResponse,
    routing::{delete, get, post},
    Json, Router,
};
use bcrypt::{hash, verify, DEFAULT_COST};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, PgPool, Row};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};


#[derive(Clone)]
struct AppState {
    db: Option<PgPool>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Claims {
    sub: i64,
    email: String,
    is_admin: bool,
    exp: usize,
}

#[derive(Deserialize)]
struct RegisterRequest {
    name: String,
    email: String,
    password: String,
}

#[derive(Deserialize)]
struct LoginRequest {
    email: String,
    password: String,
}

#[derive(Serialize)]
struct AuthResponse {
    token: String,
    user: UserResponse,
}

#[derive(Serialize, FromRow, Clone)]
struct UserResponse {
    id: i64,
    name: String,
    email: String,
    is_admin: Option<bool>,
    created_at: String,
}

#[derive(FromRow)]
struct UserWithPassword {
    id: i64,
    name: String,
    email: String,
    password_hash: String,
    is_admin: Option<bool>,
    created_at: String,
}

#[derive(Deserialize)]
struct CreateReadingRequest {
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

fn generate_token(user_id: i64, email: String, is_admin: bool) -> String {
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "secret-key".to_string());
    let exp = (chrono::Utc::now() + chrono::Duration::hours(24)).timestamp() as usize;
    let claims = Claims { sub: user_id, email, is_admin, exp };
    encode(&Header::default(), &claims, &EncodingKey::from_secret(jwt_secret.as_ref())).unwrap()
}

fn verify_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "secret-key".to_string());
    decode::<Claims>(token, &DecodingKey::from_secret(jwt_secret.as_ref()), &Validation::default())
        .map(|data| data.claims)
}

#[tokio::main]
async fn main() {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres@localhost:5432/tension".to_string());
    
    let db = match db::init_db(&database_url).await {
        Ok(pool) => {
            println!("✅ Database connected");
            Some(pool)
        }
        Err(e) => {
            eprintln!("⚠️  Database connection failed: {}. Running without database.", e);
            None
        }
    };
    
    let state = AppState { db };

    let app = Router::new()
        .route("/health", get(health))
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/api/me", get(get_current_user).layer(axum::Extension(state.clone())))
        .route("/api/readings", post(create_reading).layer(axum::Extension(state.clone())))
        .route("/api/readings/my", get(get_my_readings).layer(axum::Extension(state.clone())))
        .route("/api/readings/:id", delete(delete_my_reading).layer(axum::Extension(state.clone())))
        .route("/admin/users", get(list_users).layer(axum::Extension(state.clone())))
        .route("/admin/users/:id", delete(delete_user).layer(axum::Extension(state.clone())))
        .route("/admin/readings/:user_id", get(list_user_readings).layer(axum::Extension(state.clone())))
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state);

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(3000);
    
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("🚀 API running on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.expect("Failed to bind address");
    axum::serve(listener, app).await.expect("Server error");
}

async fn health() -> impl IntoResponse {
    (StatusCode::OK, Json(serde_json::json!({ "status": "ok" })))
}

async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let password_hash = hash(&payload.password, DEFAULT_COST).unwrap();
    
    let result = sqlx::query("INSERT INTO users (name, email, password_hash, is_admin) VALUES ($1, $2, $3, FALSE) RETURNING id")
        .bind(&payload.name)
        .bind(&payload.email)
        .bind(&password_hash)
        .fetch_one(db)
        .await;

    match result {
        Ok(row) => {
            let user_id: i64 = row.get("id");
            let user = sqlx::query_as::<_, UserResponse>("SELECT id, name, email, is_admin, created_at::text FROM users WHERE id = $1")
                .bind(user_id)
                .fetch_one(db)
                .await;
            match user {
                Ok(u) => {
                    let token = generate_token(u.id, u.email.clone(), u.is_admin.unwrap_or(false));
                    (StatusCode::CREATED, Json(AuthResponse { token, user: u })).into_response()
                }
                Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Error fetching user").into_response(),
            }
        }
        Err(_) => (StatusCode::BAD_REQUEST, "Email already exists").into_response(),
    }
}

async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let user = sqlx::query_as::<_, UserWithPassword>("SELECT id, name, email, password_hash, is_admin, created_at::text FROM users WHERE email = $1")
        .bind(&payload.email)
        .fetch_one(db)
        .await;

    match user {
        Ok(u) => {
            if verify(&payload.password, &u.password_hash).unwrap_or(false) {
                let email_clone = u.email.clone();
                let user_response = UserResponse {
                    id: u.id,
                    name: u.name,
                    email: u.email,
                    is_admin: u.is_admin,
                    created_at: u.created_at,
                };
                let token = generate_token(u.id, email_clone, u.is_admin.unwrap_or(false));
                (StatusCode::OK, Json(AuthResponse { token, user: user_response })).into_response()
            } else {
                (StatusCode::UNAUTHORIZED, "Invalid credentials").into_response()
            }
        }
        Err(_) => (StatusCode::UNAUTHORIZED, "Invalid credentials").into_response(),
    }
}

async fn get_current_user(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let auth_header = headers.get(header::AUTHORIZATION).and_then(|h| h.to_str().ok());
    let token = match auth_header {
        Some(header) if header.starts_with("Bearer ") => &header[7..],
        _ => return (StatusCode::UNAUTHORIZED, "Missing token").into_response(),
    };

    let claims = match verify_token(token) {
        Ok(c) => c,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Invalid token").into_response(),
    };

    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };

    let user = sqlx::query_as::<_, UserResponse>("SELECT id, name, email, is_admin, created_at::text FROM users WHERE id = $1")
        .bind(claims.sub)
        .fetch_one(db)
        .await;

    match user {
        Ok(u) => (StatusCode::OK, Json(u)).into_response(),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Error fetching user").into_response(),
    }
}

async fn list_users(State(state): State<AppState>) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let users = sqlx::query_as::<_, UserResponse>("SELECT id, name, email, is_admin, created_at FROM users ORDER BY created_at DESC")
        .fetch_all(db)
        .await;
    match users {
        Ok(u) => (StatusCode::OK, Json(u)).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

async fn delete_user(Path(id): Path<i64>, State(state): State<AppState>) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let result = sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(id)
        .execute(db)
        .await;
    match result {
        Ok(_) => (StatusCode::OK, Json(serde_json::json!({ "deleted": true }))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

async fn create_reading(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
    Json(payload): Json<CreateReadingRequest>,
) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let user_id = extract_user_id(&headers);
    let user_id = match user_id {
        Some(id) => id,
        None => return (StatusCode::UNAUTHORIZED, "Missing or invalid token").into_response(),
    };

    let result = sqlx::query(
        "INSERT INTO pressure_readings (user_id, systolic, diastolic, pulse, notes) VALUES ($1, $2, $3, $4, $5)"
    )
    .bind(user_id)
    .bind(payload.systolic)
    .bind(payload.diastolic)
    .bind(payload.pulse)
    .bind(payload.notes)
    .execute(db)
    .await;

    match result {
        Ok(_) => (StatusCode::CREATED, Json(serde_json::json!({ "created": true }))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

async fn get_my_readings(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let user_id = extract_user_id(&headers);
    let user_id = match user_id {
        Some(id) => id,
        None => return (StatusCode::UNAUTHORIZED, "Missing or invalid token").into_response(),
    };

    let readings = sqlx::query_as::<_, ReadingResponse>(
        "SELECT id, user_id, systolic, diastolic, pulse, notes, created_at FROM pressure_readings WHERE user_id = $1 ORDER BY created_at DESC"
    )
    .bind(user_id)
    .fetch_all(db)
    .await;

    match readings {
        Ok(r) => (StatusCode::OK, Json(r)).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

async fn list_user_readings(Path(user_id): Path<i64>, State(state): State<AppState>) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let readings = sqlx::query_as::<_, ReadingResponse>(
        "SELECT id, user_id, systolic, diastolic, pulse, notes, created_at::text FROM pressure_readings WHERE user_id = $1 ORDER BY created_at DESC"
    )
    .bind(user_id)
    .fetch_all(db)
    .await;

    match readings {
        Ok(r) => (StatusCode::OK, Json(r)).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

async fn delete_my_reading(
    Path(id): Path<i64>,
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let db = match &state.db {
        Some(db) => db,
        None => return (StatusCode::SERVICE_UNAVAILABLE, "Database not available").into_response(),
    };
    
    let user_id = extract_user_id(&headers);
    let user_id = match user_id {
        Some(id) => id,
        None => return (StatusCode::UNAUTHORIZED, "Missing or invalid token").into_response(),
    };

    let result = sqlx::query("DELETE FROM pressure_readings WHERE id = $1 AND user_id = $2")
        .bind(id)
        .bind(user_id)
        .execute(db)
        .await;

    match result {
        Ok(r) => {
            if r.rows_affected() > 0 {
                (StatusCode::OK, Json(serde_json::json!({ "deleted": true }))).into_response()
            } else {
                (StatusCode::NOT_FOUND, "Reading not found or not authorized").into_response()
            }
        }
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

fn extract_user_id(headers: &axum::http::HeaderMap) -> Option<i64> {
    let auth_header = headers.get(header::AUTHORIZATION)?.to_str().ok()?;
    if !auth_header.starts_with("Bearer ") { return None; }
    let token = &auth_header[7..];
    let claims = verify_token(token).ok()?;
    Some(claims.sub)
}
