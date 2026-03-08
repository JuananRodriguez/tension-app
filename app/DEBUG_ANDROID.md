# Debugging Android APK - Login/Registro

## Problemas Comunes y Soluciones

### 1. Verificar Conexión de Red

#### Logs del dispositivo:
```bash
# Ver logs de la app
adb logcat | grep "flutter"

# Ver logs específicos de login/registro
adb logcat | grep "🔧"

# Ver errores de red
adb logcat | grep "HTTP"
```

#### Logs esperados:
```
🔧 Register - URL: https://api-url.railway.app/auth/register
🔧 Login - URL: https://api-url.railway.app/auth/login
🔧 Login - Status: 200
🔧 Login - Response: {"token":"...","user":{...}}
```

### 2. Verificar Variables de Entorno

#### En el APK, la URL debe ser:
```
https://api-url.railway.app
```

#### Para verificar, revisa los logs:
```
🔧 Register - URL: https://api-url.railway.app/auth/register
```

### 3. Permisos de Android

El APK incluye estos permisos:
- ✅ `INTERNET` - Acceso a internet
- ✅ `ACCESS_NETWORK_STATE` - Estado de red
- ✅ `USE_FINGERPRINT` - Autenticación biométrica
- ✅ `USE_BIOMETRIC` - Autenticación biométrica

### 4. Configuración de Seguridad

- ✅ `usesCleartextTraffic="true"` - Permite conexiones HTTP/HTTPS
- ✅ `networkSecurityConfig` - Configuración específica para Railway

### 5. Pasos para Debugging

#### Paso 1: Instalar APK con logs
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### Paso 2: Abrir app y revisar logs
```bash
adb logcat | grep "🔧"
```

#### Paso 3: Probar conexión manual
```bash
# Test de conexión a la API
curl -X POST https://api-url.railway.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 6. Errores Comunes

#### Error: "Error de conexión"
- **Causa**: Sin internet o URL incorrecta
- **Solución**: Verificar URL en logs

#### Error: "Invalid credentials"
- **Causa**: Usuario no existe o contraseña incorrecta
- **Solución**: Crear usuario nuevo

#### Error: Timeout
- **Causa**: Conexión lenta o bloqueada
- **Solución**: Revisar configuración de red

### 7. Verificación de Variables

Para verificar que las variables están correctas:

1. **Desinstalar APK anterior**
2. **Instalar nuevo APK**
3. **Abrir app inmediatamente**
4. **Revisar logs iniciales**

### 8. Si aún no funciona

#### Opción 1: APK con modo debug
```bash
flutter build apk --debug
```

#### Opción 2: Verificar configuración Railway
- Revisar que la API esté funcionando
- Verificar healthcheck: `curl https://api-url.railway.app/health`

#### Opción 3: Test con usuario conocido
```bash
# Usar usuario que ya existe
Email: test@example.com
Password: password123
```

## Comandos Útiles

```bash
# Instalar APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs en tiempo real
adb logcat | grep "flutter"

# Ver logs de errores
adb logcat | grep "AndroidRuntime"

# Desinstalar app
adb uninstall com.example.app

# Ver dispositivos conectados
adb devices
```
