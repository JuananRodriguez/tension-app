# Debugging Autenticación Biométrica Fallida

## 🔍 Pasos para Diagnóstico

### 1. Instalar APK y ver logs en tiempo real
```bash
# Instalar APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs biométricos detallados
adb logcat | grep "🔧"
```

### 2. Probar el flujo y revisar logs esperados

#### Al hacer clic en botón biométrico:
```
🔧 LoginScreen - Iniciando autenticación biométrica...
🔧 Auth - Iniciando autenticación biométrica...
🔧 Auth - Verificando biometría para login...
🔧 Auth - use_biometric para login: true
🔧 Auth - Credenciales encontradas, verificando dispositivo...
🔧 Biometric - Verificando soporte del dispositivo...
🔧 Biometric - canCheckBiometrics: true
🔧 Biometric - isDeviceSupported: true
🔧 Biometric - Soporte final: true
🔧 Biometric - Verificando biometría configurada...
🔧 Biometric - Tipos disponibles: [BiometricType.fingerprint]
🔧 Biometric - Tiene biometría configurada: true
🔧 Auth - Puede usar biometría para login: true
🔧 Auth - Verificando huella dactilar...
```

#### Si falla en el paso biométrico:
```
🔧 Biometric - Error en authenticateWithBiometrics: [ERROR_MESSAGE]
🔧 Auth - Autenticación biométrica fallida
🔧 LoginScreen - Autenticación biométrica fallida: [ERROR_MESSAGE]
```

## ⚠️ Errores Comunes y Soluciones

### Error 1: "BiometryLockedException"
**Logs:**
```
🔧 Biometric - Error en authenticateWithBiometrics: BiometricLockedException
🔧 Biometric - Demasiados intentos fallidos, dispositivo bloqueado
```
**Solución:**
- Esperar 30 segundos
- Desbloquear dispositivo con PIN/patrón
- Reintentar

### Error 2: "NotEnrolledException"
**Logs:**
```
🔧 Biometric - Error en authenticateWithBiometrics: NotEnrolledException
🔧 Biometric - No hay huella configurada
```
**Solución:**
- Configurar huella dactilar en Android Settings
- Settings > Security > Fingerprint > Add fingerprint

### Error 3: "NotAvailableException"
**Logs:**
```
🔧 Biometric - Error en authenticateWithBiometrics: NotAvailableException
🔧 Biometric - Biometría no disponible en este dispositivo
```
**Solución:**
- Verificar que dispositivo tenga sensor biométrico
- Actualizar Android a versión compatible

### Error 4: "PermanentlyLockedOut"
**Logs:**
```
🔧 Biometric - Error en authenticateWithBiometrics: PermanentlyLockedOutException
🔧 Biometric - Bloqueo permanente, requiere desbloqueo del dispositivo
```
**Solución:**
- Reiniciar dispositivo
- O desbloquear con PIN/patrón

### Error 5: "Credenciales no encontradas"
**Logs:**
```
🔧 Auth - No hay credenciales guardadas
🔧 Auth - use_biometric: true
🔧 Auth - biometric_email: null
🔧 Auth - biometric_password: null
```
**Solución:**
- Habilitar biometría nuevamente
- Login tradicional → aceptar diálogo biometría

## 🔧 Comandos de Debugging

### Ver estado de sensores biométricos:
```bash
adb shell dumpsys fingerprint
```

### Ver SharedPreferences:
```bash
adb shell run-as com.example.app cat /data/data/com.example.app/shared_prefs/flutter.SharedPreferences.xml
```

### Forzar reinicio de servicios biométricos:
```bash
adb shell stop && adb shell start
```

## 🎱 Checklist para Solución

- [ ] **Dispositivo compatible**: Tiene sensor biométrico
- [ ] **Huella configurada**: En Android Settings
- [ ] **Credenciales guardadas**: use_biometric = true
- [ ] **Sin bloqueos**: No hay bloqueos temporales
- [ ] **Permisos correctos**: USE_FINGERPRINT, USE_BIOMETRIC

## 📱 Si el problema persiste

### Opción 1: APK con modo debug
```bash
flutter build apk --debug
```

### Opción 2: Test con emulador
```bash
# Crear emulador con soporte biométrico
flutter emulators --create --name biometric_test
```

### Opción 3: Verificar configuración manual
1. Ir a Settings > Security > Fingerprint
2. Verificar que haya al menos una huella configurada
3. Probar desbloqueo del dispositivo con huella

## 🚀 Prueba Final

1. **Limpiar datos de la app**: `adb shell pm clear com.example.app`
2. **Instalar APK**: `adb install build/app/outputs/flutter-apk/app-release.apk`
3. **Registrar usuario**: Con biometría habilitada
4. **Logout**: Cerrar sesión
5. **Login biométrico**: Debería funcionar

## 📞 Si nada funciona

Revisar logs completos:
```bash
adb logcat | grep -E "(🔧|Biometric|Fingerprint)"
```

Y compartir el error específico que aparece.
