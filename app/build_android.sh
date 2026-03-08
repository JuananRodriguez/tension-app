#!/bin/bash

# Build APK para Android con variables de entorno de producción
echo "🔨 Construyendo APK para producción..."

# Copiar archivo de entorno de producción
cp .env.production .env

# Limpiar builds anteriores
flutter clean

# Construir APK release
flutter build apk --release --no-shrink

echo "✅ APK construido exitosamente"
echo "📍 Ubicación: build/app/outputs/flutter-apk/app-release.apk"

# Restaurar archivo de entorno de desarrollo
git checkout .env

echo "🎯 APK listo para instalación"
