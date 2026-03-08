#!/bin/bash

# Build APK firmado para distribución
echo "🔨 Construyendo APK firmado para producción..."

# Copiar archivo de entorno de producción
cp .env.production .env

# Limpiar builds anteriores
flutter clean

# Construir APK release firmado
flutter build apk --release --no-shrink

echo "✅ APK firmado construido exitosamente"
echo "📍 Ubicación: build/app/outputs/flutter-apk/app-release.apk"

# Restaurar archivo de entorno de desarrollo
git checkout .env

# Verificar si el APK existe
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "📱 APK listo para instalación en Android"
    echo "📊 Tamaño del APK: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
    echo "🔐 El APK está firmado y listo para distribución"
else
    echo "❌ Error: No se pudo construir el APK"
    exit 1
fi
