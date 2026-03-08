# Debugging Autenticación Biométrica - Android

## 🔍 Logs para Diagnóstico

### Instalar APK con logs biométricos:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Ver logs biométricos en tiempo real:
```bash
# Logs biométricos específicos
adb logcat | grep "🔧 Biometric"

# Logs de autenticación
adb logcat | grep "🔧 Auth"

# Logs de pantalla de login
adb logcat | grep "🔧 LoginScreen"

# Todos los logs juntos
adb logcat | grep "🔧"
```

## 📋 Flujo Esperado de Logs

### 1. Al iniciar la app:
```
🔧 Auth - Verificando si puede usar biometría...
🔧 Auth - use_biometric guardado: true/false
🔧 Biometric - Verificando soporte del dispositivo...
🔧 Biometric - canCheckBiometrics: true
🔧 Biometric - isDeviceSupported: true
🔧 Biometric - Soporte final: true
🔧 Biometric - Verificando biometría configurada...
🔧 Biometric - Tipos disponibles: [BiometricType.fingerprint]
🔧 Biometric - Tiene biometría configurada: true
🔧 Auth - Puede usar biometría: true
🔧 LoginScreen - Puede usar biometría para login: true/false
```

### 2. Al hacer clic en botón biométrico:
```
🔧 LoginScreen - Iniciando autenticación biométrica...
🔧 Auth - Iniciando autenticación biométrica...
🔧 Auth - Condiciones cumplidas, intentando biometría...
🔧 Biometric - Iniciando autenticación biométrica...
🔧 Biometric - Autenticación exitosa: true
🔧 Auth - Resultado biometría: true
🔧 LoginScreen - Autenticación biométrica exitosa
```

## ⚠️ Problemas Comunes y Soluciones

### Problema 1: "No hay biometría configurada"
**Logs:**
```
🔧 Biometric - Tipos disponibles: []
🔧 Biometric - Tiene biometría configurada: false
```

**Solución:**
- Configurar huella dactilar en Android
- Settings > Security > Fingerprint > Add fingerprint

### Problema 2: "Dispositivo no soportado"
**Logs:**
```
🔧 Biometric - canCheckBiometrics: false
🔧 Biometric - isDeviceSupported: false
```

**Solución:**
- Verificar que el dispositivo tenga sensor biométrico
- Actualizar Android a versión compatible

### Problema 3: "Biometría no habilitada en preferencias"
**Logs:**
```
🔧 Auth - use_biometric guardado: false
🔧 Auth - Biometría no habilitada en preferencias
```

**Solución:**
- Registrarse con checkbox marcado
- O habilitar manualmente en SharedPreferences

### Problema 4: "No hay usuario actual"
**Logs:**
```
🔧 Auth - No hay usuario actual, no se puede usar biometría
```

**Solución:**
- Iniciar sesión con email/contraseña primero
- La biometría requiere sesión previa guardada

### Problema 5: "Demasiados intentos fallidos"
**Logs:**
```
🔧 Biometric - Error en authenticateWithBiometrics: BiometricLockedException
🔧 Biometric - Demasiados intentos fallidos, dispositivo bloqueado
```

**Solución:**
- Esperar 30 segundos
- O desbloquear dispositivo con PIN/patrón

## 🔧 Comandos Útiles

### Verificar sensores biométricos:
```bash
adb shell dumpsys fingerprint
```

### Verificar permisos:
```bash
adb shell dumpsys package com.example.app | grep permission
```

### Forzar reinicio de servicios biométricos:
```bash
adb shell stop && adb shell start
```

### Limpiar datos de la app:
```bash
adb shell pm clear com.example.app
```

## 📱 Pasos para Testing

### Paso 1: Instalar APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Paso 2: Abrir app y registrar usuario
- Marcar "Habilitar autenticación biométrica"
- Completar registro

### Paso 3: Cerrar app y volver a abrir
- Debería mostrar botón biométrico
- Ver logs de disponibilidad

### Paso 4: Probar autenticación biométrica
- Clic en botón de huella
- Ver logs del proceso

## 🎯 Checklist de Funcionalidad

- [ ] **Permisos biométricos**: `USE_FINGERPRINT`, `USE_BIOMETRIC`
- [ ] **Huella configurada**: En configuración Android
- [ ] **Sesión guardada**: Usuario logueado previamente
- [ ] **Preferencia activada**: `use_biometric = true`
- [ ] **Dispositivo compatible**: Sensor biométrico presente

## 🚀 Si aún no funciona

### Opción 1: APK con modo debug
```bash
flutter build apk --debug
```

### Opción 2: Verificar configuración manual
```bash
# Ver SharedPreferences
adb shell run-as com.example.app ls /data/data/com.example.app/shared_prefs
```

### Opción 3: Test con emulador
```bash
# Crear emulador con soporte biométrico
flutter emulators --create --name biometric_test
```
