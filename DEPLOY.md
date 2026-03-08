# Despliegue de Tension App

## Despliegue API Rust

### Opción 1: Railway (Recomendado)
```bash
# 1. Instalar Railway CLI
npm install -g @railway/cli

# 2. Login en Railway
railway login

# 3. Inicializar proyecto
cd api
railway init

# 4. Crear railway.json
cat > railway.json << EOF
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "cargo run",
    "healthcheckPath": "/health"
  }
}
EOF

# 5. Desplegar
railway up
```

### Opción 2: DigitalOcean App Platform
```bash
# 1. Crear Dockerfile en api/
cat > Dockerfile << EOF
FROM rust:1.70 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/api /usr/local/bin/api
EXPOSE 3000
CMD ["api"]
EOF

# 2. Desplegar via DigitalOcean dashboard
```

### Opción 3: VPS Linux (Ubuntu/Debian)
```bash
# 1. Configurar servidor
ssh root@tu-servidor.com

# 2. Instalar dependencias
apt update
apt install -y sqlite3 nginx

# 3. Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 4. Clonar y compilar
git clone https://github.com/JuananRodriguez/tension-app.git
cd tension-app/api
cargo build --release

# 5. Configurar systemd
sudo tee /etc/systemd/system/tension-api.service > /dev/null << EOF
[Unit]
Description=Tension App API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/tension-app/api
ExecStart=/root/.cargo/bin/cargo run --release
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. Iniciar servicio
sudo systemctl enable tension-api
sudo systemctl start tension-api

# 7. Configurar Nginx como reverse proxy
sudo tee /etc/nginx/sites-available/tension-app > /dev/null << EOF
server {
    listen 80;
    server_name tu-dominio.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/tension-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Configuración API para Producción

### Variables de Entorno
```bash
# Crear .env en api/
cat > .env << EOF
DATABASE_URL=sqlite:///app/tension.db
JWT_SECRET=super-secreto-muy-largo-para-produccion
PORT=3000
CORS_ORIGIN=https://tu-dominio.com
EOF
```

### Actualizar main.rs para producción
```rust
// Añadir al principio de main.rs
use std::env;

// Reemplazar la inicialización de la app
let db_url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://tension.db".to_string());
let jwt_secret = env::var("JWT_SECRET").unwrap_or_else(|_| "secret-key".to_string());
let port = env::var("PORT").unwrap_or_else(|_| "3000".to_string());
```

## Generar APK Android

### 1. Configurar Flutter para release
```bash
cd app

# 1.1 Configurar versión en pubspec.yaml
# Asegurar que tienes:
# version: 1.0.0+1

# 1.2 Configurar Android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.juanan.tensionapp"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}

# 1.3 Crear keystore para firmar
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Configurar keystore
```bash
# Crear key.properties en android/
cat > android/key.properties << EOF
storePassword=tu-contraseña
keyPassword=tu-contraseña
keyAlias=upload
storeFile=../upload-keystore.jks
EOF
```

### 3. Actualizar Android build.gradle
```gradle
// En android/app/build.gradle, añadir:
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

### 4. Generar APK
```bash
# 4.1 Limpiar proyecto
flutter clean
flutter pub get

# 4.2 Generar APK release
flutter build apk --release

# 4.3 El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk
```

### 5. Opciones de distribución

#### Google Play Store
```bash
# Generar AAB para Play Store
flutter build appbundle --release

# Subir a Google Play Console
# build/app/outputs/bundle/release/app-release.aab
```

#### Distribución directa
```bash
# Opción 1: Compartir APK directamente
# Subir el APK a Google Drive, Dropbox, etc.

# Opción 2: Usar servicios como:
# - AppCenter (Microsoft)
# - Firebase App Distribution
# - TestFlight (iOS)

# Opción 3: Crear página web de descarga
# Subir APK a GitHub Releases
```

## Consideraciones de Seguridad

### API
- Usar HTTPS con certificado SSL (Let's Encrypt gratis)
- Cambiar JWT_SECRET a algo seguro
- Validar CORS origin
- Implementar rate limiting
- Logs y monitoreo

### App Android
- No hardcodear URLs de API
- Usar variables de entorno o config remota
- Validar certificados SSL
- Implementar actualizaciones automáticas
- Proguard para ofuscar código

## Costos Estimados

### API
- Railway: $5-20/mes
- DigitalOcean: $5-10/mes
- VPS: $5-15/mes

### App
- Google Play Developer: $25 (único)
- Hosting APK: $0-10/mes

## Alternativas Simples

### Para testing/desarrollo
- **API**: ngrok para exponer local
- **APK**: flutter build apk --debug (más grande, sin optimizar)

### Para producción rápida
- **API**: Railway o Render
- **APK**: AppCenter para distribución
