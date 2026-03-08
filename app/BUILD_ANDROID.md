# Build para Android - APK Instalable

## Scripts disponibles

### 1. Build APK Básico
```bash
./build_android.sh
```
- Crea APK con variables de entorno de producción
- No está firmado (solo para desarrollo)

### 2. Build APK Firmado (Recomendado)
```bash
./build_signed_apk.sh
```
- Crea APK firmado para distribución
- Listo para instalación en cualquier dispositivo Android
- Incluye variables de entorno de producción

## Variables de Entorno

### Desarrollo (.env)
```env
API_BASE_URL=http://192.168.68.65:3000
ENV=development
```

### Producción (.env.production)
```env
API_BASE_URL=https://api-url.railway.app
ENV=production
```

## Proceso de Build

1. **Ejecutar script**:
   ```bash
   ./build_signed_apk.sh
   ```

2. **Ubicación del APK**:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Instalación**:
   - Transferir APK al dispositivo Android
   - Habilitar "Fuentes desconocidas" en configuración
   - Instalar APK

## Configuración de Firma

Para producción, considera configurar tu propia firma digital:

1. **Generar keystore**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configurar en build.gradle.kts**:
   ```kotlin
   android {
       signingConfigs {
           create("release") {
               storeFile = file("../upload-keystore.jks")
               storePassword = System.getenv("KSTOREPWD")
               keyAlias = System.getenv("KEYALIAS")
               keyPassword = System.getenv("KEYPWD")
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

## Comandos Útiles

### Verificar dispositivo conectado
```bash
adb devices
```

### Instalar APK via ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Ver logs de la app
```bash
adb logcat | grep "flutter"
```

## Notas Importantes

- ✅ **Variables de entorno**: El script automáticamente usa `.env.production`
- ✅ **APK firmado**: Listo para distribución en Google Play Store
- ✅ **Optimizado**: `--no-shrink` reduce tamaño del APK
- ✅ **Seguridad**: Incluye configuración de producción (HTTPS API)
