import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_service.dart';
import '../models/user.dart';

class AuthService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.68.65:3000';
  static String? _token;
  static User? _currentUser;

  static String? get token => _token;
  static User? get currentUser => _currentUser;

  // Claves para SharedPreferences
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUseBiometric = 'use_biometric';
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';

  static Future<void> setAuth(String token, User user, {bool useBiometric = false, String? email, String? password}) async {
    _token = token;
    _currentUser = user;
    
    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    await prefs.setBool(_keyUseBiometric, useBiometric);
    
    // Si biometría está habilitada, guardar credenciales para login automático
    if (useBiometric && email != null && password != null) {
      debugPrint('🔧 Auth - Guardando credenciales para biometría...');
      // Simple encoding (en producción usar encriptación más segura)
      final encodedEmail = base64Encode(utf8.encode(email));
      final encodedPassword = base64Encode(utf8.encode(password));
      await prefs.setString(_keyBiometricEmail, encodedEmail);
      await prefs.setString(_keyBiometricPassword, encodedPassword);
    }
  }

  static Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUserData = prefs.getString('user_data');
    
    if (savedToken != null && savedUserData != null) {
      _token = savedToken;
      try {
        _currentUser = User.fromJson(jsonDecode(savedUserData));
      } catch (e) {
        // Si hay error al parsear, limpiar sesión
        await clearAuth();
      }
    }
  }

  static Future<bool> get canUseBiometric async {
    try {
      debugPrint('🔧 Auth - Verificando si puede usar biometría...');
      
      final prefs = await SharedPreferences.getInstance();
      final useBiometric = prefs.getBool('use_biometric') ?? false;
      debugPrint('🔧 Auth - use_biometric guardado: $useBiometric');
      
      if (!useBiometric) {
        debugPrint('🔧 Auth - Biometría no habilitada en preferencias');
        return false;
      }
      
      final isSupported = await BiometricService.isDeviceSupported();
      debugPrint('🔧 Auth - Dispositivo soportado: $isSupported');
      
      final isEnrolled = await BiometricService.isBiometricEnrolled();
      debugPrint('🔧 Auth - Biometría configurada: $isEnrolled');
      
      final result = useBiometric && isSupported && isEnrolled;
      debugPrint('🔧 Auth - Puede usar biometría: $result');
      
      return result;
    } catch (e) {
      debugPrint('🔧 Auth - Error en canUseBiometric: $e');
      return false;
    }
  }

  static Future<bool> canUseBiometricForLogin() async {
    try {
      debugPrint('🔧 Auth - Verificando biometría para login...');
      
      final prefs = await SharedPreferences.getInstance();
      final useBiometric = prefs.getBool(_keyUseBiometric) ?? false;
      debugPrint('🔧 Auth - use_biometric para login: $useBiometric');
      
      if (!useBiometric) {
        debugPrint('🔧 Auth - Biometría no habilitada');
        return false;
      }
      
      // Verificar si hay credenciales guardadas para biometría
      final savedEmail = prefs.getString(_keyBiometricEmail);
      final savedPassword = prefs.getString(_keyBiometricPassword);
      
      if (savedEmail == null || savedPassword == null) {
        debugPrint('🔧 Auth - No hay credenciales guardadas para biometría');
        return false;
      }
      
      debugPrint('🔧 Auth - Credenciales encontradas, verificando dispositivo...');
      
      final isSupported = await BiometricService.isDeviceSupported();
      final isEnrolled = await BiometricService.isBiometricEnrolled();
      
      final result = useBiometric && isSupported && isEnrolled;
      debugPrint('🔧 Auth - Puede usar biometría para login: $result');
      
      return result;
    } catch (e) {
      debugPrint('🔧 Auth - Error en canUseBiometricForLogin: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> authenticateWithBiometric() async {
    try {
      debugPrint('🔧 Auth - Iniciando autenticación biométrica...');
      
      // Verificar si se puede usar biometría
      if (!await canUseBiometricForLogin()) {
        debugPrint('🔧 Auth - No cumple condiciones para biometría');
        return {'success': false, 'error': 'Biometría no disponible'};
      }
      
      debugPrint('🔧 Auth - Condiciones OK, verificando huella dactilar...');
      
      // Verificar estado del dispositivo antes de autenticar
      final isSupported = await BiometricService.isDeviceSupported();
      final isEnrolled = await BiometricService.isBiometricEnrolled();
      final availableBiometrics = await BiometricService.getAvailableBiometrics();
      
      debugPrint('🔧 Auth - Estado final del dispositivo:');
      debugPrint('🔧 Auth - isSupported: $isSupported');
      debugPrint('🔧 Auth - isEnrolled: $isEnrolled');
      debugPrint('🔧 Auth - availableBiometrics: $availableBiometrics');
      
      if (!isSupported) {
        return {'success': false, 'error': 'Dispositivo no soporta biometría'};
      }
      
      if (!isEnrolled) {
        return {'success': false, 'error': 'No hay huella configurada en el dispositivo'};
      }
      
      if (availableBiometrics.isEmpty) {
        return {'success': false, 'error': 'No hay sensores biométricos disponibles'};
      }
      
      debugPrint('🔧 Auth - Dispositivo listo, iniciando escáner biométrico...');
      debugPrint('🔧 Auth - ⚠️ Por favor, pon tu huella en el sensor...');
      
      final biometricResult = await BiometricService.authenticateWithBiometrics();
      
      if (!biometricResult) {
        debugPrint('🔧 Auth - ❌ Escáner biométrico falló o fue cancelado por el usuario');
        return {
          'success': false, 
          'error': 'Autenticación cancelada. Por favor, intenta nuevamente y mantén tu huella en el sensor hasta que se complete.'
        };
      }
      
      debugPrint('🔧 Auth - ✅ Huella verificada exitosamente!');
      debugPrint('🔧 Auth - Recuperando credenciales guardadas...');
      
      // Obtener credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyBiometricEmail);
      final savedPassword = prefs.getString(_keyBiometricPassword);
      
      if (savedEmail == null || savedPassword == null) {
        debugPrint('🔧 Auth - ❌ No hay credenciales guardadas');
        return {'success': false, 'error': 'Credenciales no encontradas'};
      }
      
      debugPrint('🔧 Auth - ✅ Credenciales encontradas');
      
      // Decodificar credenciales
      final email = utf8.decode(base64Decode(savedEmail));
      final password = utf8.decode(base64Decode(savedPassword));
      
      debugPrint('🔧 Auth - Email recuperado: ${email.substring(0, 3)}***');
      debugPrint('🔧 Auth - Iniciando login automático con API...');
      
      // Hacer login automático
      return await login(email, password);
    } catch (e) {
      debugPrint('🔧 Auth - ❌ Error en authenticateWithBiometric: $e');
      
      // Analizar error específico
      String errorMessage = 'Error desconocido';
      if (e.toString().contains('BiometricLockedException')) {
        errorMessage = 'Demasiados intentos fallidos. Espera 30 segundos.';
      } else if (e.toString().contains('NotEnrolledException')) {
        errorMessage = 'No hay huella configurada en el dispositivo.';
      } else if (e.toString().contains('NotAvailableException')) {
        errorMessage = 'Biometría no disponible en este dispositivo.';
      } else if (e.toString().contains('PermanentlyLockedOut')) {
        errorMessage = 'Dispositivo bloqueado permanentemente.';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = 'Error del sistema: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  static Future<Map<String, dynamic>> enableBiometric(String email, String password) async {
    try {
      debugPrint('🔧 Auth - Habilitando biometría para usuario existente...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar que hay sesión activa
      if (_token == null || _currentUser == null) {
        debugPrint('🔧 Auth - No hay sesión activa para habilitar biometría');
        return {'success': false, 'error': 'Debes iniciar sesión primero'};
      }
      
      // Guardar credenciales para biometría
      final encodedEmail = base64Encode(utf8.encode(email));
      final encodedPassword = base64Encode(utf8.encode(password));
      await prefs.setString(_keyBiometricEmail, encodedEmail);
      await prefs.setString(_keyBiometricPassword, encodedPassword);
      await prefs.setBool(_keyUseBiometric, true);
      
      debugPrint('🔧 Auth - Biometría habilitada exitosamente');
      return {'success': true};
    } catch (e) {
      debugPrint('🔧 Auth - Error habilitando biometría: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  static Future<bool> hasBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyBiometricEmail);
      final savedPassword = prefs.getString(_keyBiometricPassword);
      final useBiometric = prefs.getBool(_keyUseBiometric) ?? false;
      
      return useBiometric && savedEmail != null && savedPassword != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearAuth() async {
    debugPrint('🔧 Auth - Limpiando sesión actual (manteniendo biometría)...');
    _token = null;
    _currentUser = null;
    
    // Limpiar solo sesión, mantener credenciales biométricas
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserData);
    
    // Verificar que credenciales biométricas se mantienen
    final biometricEmail = prefs.getString(_keyBiometricEmail);
    final biometricPassword = prefs.getString(_keyBiometricPassword);
    final useBiometric = prefs.getBool(_keyUseBiometric);
    
    debugPrint('🔧 Auth - Credenciales biométricas mantenidas:');
    debugPrint('🔧 Auth - use_biometric: $useBiometric');
    debugPrint('🔧 Auth - biometric_email: ${biometricEmail != null ? "guardado" : "null"}');
    debugPrint('🔧 Auth - biometric_password: ${biometricPassword != null ? "guardado" : "null"}');
  }

  static Future<void> clearBiometric() async {
    // Limpiar solo credenciales biométricas
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUseBiometric);
    await prefs.remove(_keyBiometricEmail);
    await prefs.remove(_keyBiometricPassword);
  }

  static Future<void> clearAll() async {
    // Limpiar todo (sesión + biometría)
    _token = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyUseBiometric);
    await prefs.remove(_keyBiometricEmail);
    await prefs.remove(_keyBiometricPassword);
  }

  static bool get isAuthenticated => _token != null;
  static bool get isAdmin => _currentUser?.isAdmin ?? false;

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> register(String name, String email, String password, {bool useBiometric = false}) async {
    try {
      debugPrint('🔧 Register - URL: $baseUrl/auth/register');
      debugPrint('🔧 Register - Data: {name: $name, email: $email}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      debugPrint('🔧 Register - Status: ${response.statusCode}');
      debugPrint('🔧 Register - Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await setAuth(
          data['token'], 
          User.fromJson(data['user']), 
          useBiometric: useBiometric,
          email: email,
          password: password,
        );
        return {'success': true};
      }
      return {'success': false, 'error': response.body};
    } catch (e) {
      debugPrint('🔧 Register - Error: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password, {bool useBiometric = false}) async {
    try {
      debugPrint('🔧 Login - URL: $baseUrl/auth/login');
      debugPrint('🔧 Login - Data: {email: $email}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('🔧 Login - Status: ${response.statusCode}');
      debugPrint('🔧 Login - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setAuth(
          data['token'], 
          User.fromJson(data['user']),
          useBiometric: useBiometric,
          email: email,
          password: password,
        );
        return {'success': true};
      }
      return {'success': false, 'error': 'Invalid credentials'};
    } catch (e) {
      debugPrint('🔧 Login - Error: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<void> logout() async {
    await clearAuth();
  }
}
