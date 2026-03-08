# Guía de Prueba - Login Biométrico

## 📋 Pasos para Probar el Login Biométrico

### Paso 1: Instalar el APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Paso 2: Registrar Usuario con Biometría
1. Abrir la app
2. Click en "¿No tienes cuenta? Regístrate"
3. Llenar formulario:
   - Nombre: Test User
   - Email: test@example.com
   - Password: password123
4. **MARCAR** el checkbox "Habilitar autenticación biométrica"
5. Click en "Registrarse"

### Paso 3: Verificar Registro Exitoso
- Debería navegar automáticamente a la pantalla principal
- La sesión está guardada en SharedPreferences

### Paso 4: Cerrar Sesión
1. En la pantalla principal, buscar opción de logout
2. Click en logout/cerrar sesión
3. Debería volver a la pantalla de login

### Paso 5: Probar Login Biométrico
1. En la pantalla de login, debería aparecer:
   - "Usar autenticación biométrica"
   - Botón "Iniciar con huella" 🚀
2. Click en "Iniciar con huella"
3. Poner huella dactilar en el sensor
4. Debería autenticar y navegar a pantalla principal

## 🔍 Logs Esperados

### Durante el registro:
```
🔧 Auth - use_biometric guardado: true
🔧 Register - Status: 201
🔧 Register - Response: {"token":"...","user":{...}}
```

### Al volver a login:
```
🔧 Auth - Verificando biometría para login...
🔧 Auth - Sesión guardada encontrada, verificando dispositivo...
🔧 Biometric - Tipos disponibles: [BiometricType.fingerprint]
🔧 LoginScreen - Puede usar biometría para login: true
```

### Al hacer clic en huella:
```
🔧 LoginScreen - Iniciando autenticación biométrica...
🔧 Auth - Cargando sesión guardada...
🔧 Auth - Condiciones cumplidas, intentando biometría...
🔧 Biometric - Autenticación exitosa: true
🔧 LoginScreen - Autenticación biométrica exitosa
```

## ⚠️ Si no aparece el botón biométrico

### Verificar logs:
```bash
adb logcat | grep "🔧 LoginScreen"
```

### Posibles problemas:

#### Problema 1: "use_biometric: false"
```
🔧 Auth - use_biometric para login: false
```
**Solución**: Registrar usuario con checkbox marcado

#### Problema 2: "No hay sesión guardada"
```
🔧 Auth - No hay sesión guardada, no se puede usar biometría
```
**Solución**: Iniciar sesión con email/contraseña primero

#### Problema 3: "Dispositivo no soportado"
```
🔧 Biometric - Soporte final: false
```
**Solución**: Usar dispositivo con sensor biométrico

#### Problema 4: "No hay biometría configurada"
```
🔧 Biometric - Tiene biometría configurada: false
```
**Solución**: Configurar huella en Android Settings

## 🎱 Flujo Completo de Prueba

### Opción A: Flujo Normal
1. **Registrar** → con biometría habilitada
2. **Logout** → cerrar sesión
3. **Login biométrico** → usar huella

### Opción B: Forzar Prueba
1. **Limpiar datos** de la app
2. **Registrar** → sin marcar biometría
3. **Login tradicional** → email/contraseña
4. **Logout** → cerrar sesión
5. **Editar SharedPreferences** → `use_biometric: true`
6. **Login biométrico** → debería aparecer

## 🔧 Comandos de Debugging

### Ver SharedPreferences:
```bash
adb shell run-as com.example.app cat /data/data/com.example.app/shared_prefs/flutter.SharedPreferences.xml
```

### Forzar biometría:
```bash
# Si no aparece, verificar que tenga valor true
adb shell "echo '<map><boolean name=\"use_biometric\" value=\"true\" /></map>' > /data/data/com.example.app/shared_prefs/flutter SharedPreferences.xml"
```

### Limpiar y empezar de nuevo:
```bash
adb shell pm clear com.example.app
```

## ✅ Checklist Final

- [ ] **APK instalado** con permisos biométricos
- [ ] **Huella configurada** en dispositivo Android
- [ ] **Usuario registrado** con checkbox marcado
- [ ] **Sesión guardada** en SharedPreferences
- [ ] **Botón biométrico visible** en pantalla login
- [ ] **Autenticación exitosa** con huella

## 📱 Si todo funciona correctamente

El flujo debería ser:
1. Registro con biometría ✅
2. Logout ✅
3. Login biométrico aparece ✅
4. Huella funciona ✅
5. Navegación a pantalla principal ✅

¡Listo! El login biométrico debería funcionar perfectamente.
