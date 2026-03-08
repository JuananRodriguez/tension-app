import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    try {
      debugPrint('🔧 Biometric - Verificando soporte del dispositivo...');
      
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      debugPrint('🔧 Biometric - canCheckBiometrics: $canAuthenticateWithBiometrics');
      debugPrint('🔧 Biometric - isDeviceSupported: $isDeviceSupported');
      
      final result = canAuthenticateWithBiometrics && isDeviceSupported;
      debugPrint('🔧 Biometric - Soporte final: $result');
      
      return result;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en isDeviceSupported: $e');
      return false;
    }
  }

  static Future<bool> isBiometricEnrolled() async {
    try {
      debugPrint('🔧 Biometric - Verificando biometría configurada...');
      
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        debugPrint('🔧 Biometric - No se puede verificar biometría');
        return false;
      }
      
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('🔧 Biometric - Tipos disponibles: $availableBiometrics');
      
      final hasBiometrics = availableBiometrics.isNotEmpty;
      debugPrint('🔧 Biometric - Tiene biometría configurada: $hasBiometrics');
      
      return hasBiometrics;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en isBiometricEnrolled: $e');
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      debugPrint('🔧 Biometric - Iniciando autenticación biométrica...');
      
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Autentícate con tu huella dactilar para continuar',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      
      debugPrint('🔧 Biometric - Resultado autenticación: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en autenticación biométrica: $e');
      return false;
    }
  }

  // Método para solicitar permisos biométricos activamente
  static Future<Map<String, dynamic>> requestBiometricPermissions() async {
    try {
      debugPrint('🔧 Biometric - 🚪 Solicitando permisos biométricos...');
      
      // Verificar estado actual
      bool canCheck = await _auth.canCheckBiometrics;
      debugPrint('🔧 Biometric - canCheckBiometrics inicial: $canCheck');
      
      // Intentar autenticación para forzar solicitud de permisos
      bool permissionGranted = false;
      String errorMessage = '';
      
      try {
        debugPrint('🔧 Biometric - 🔓 Intentando autenticación para solicitar permisos...');
        
        final result = await _auth.authenticate(
          localizedReason: 'Permite el acceso a la autenticación biométrica',
          options: const AuthenticationOptions(
            biometricOnly: false,  // Permitir PIN/patrón como fallback
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        
        permissionGranted = result;
        debugPrint('🔧 Biometric - ✅ Permisos concedidos: $result');
        
      } catch (e) {
        debugPrint('🔧 Biometric - ❌ Error solicitando permisos: $e');
        errorMessage = e.toString();
        
        // Analizar error específico
        if (e.toString().contains('NotAvailable')) {
          errorMessage = 'Biometría no disponible en este dispositivo';
        } else if (e.toString().contains('NotEnrolled')) {
          errorMessage = 'No hay huella configurada en el dispositivo';
        } else if (e.toString().contains('LockedOut')) {
          errorMessage = 'Dispositivo bloqueado temporalmente';
        } else if (e.toString().contains('PermanentlyLockedOut')) {
          errorMessage = 'Dispositivo bloqueado permanentemente';
        }
      }
      
      // Verificar estado final
      final canCheckAfter = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final availableBiometrics = await _auth.getAvailableBiometrics();
      
      debugPrint('🔧 Biometric - 📋 Estado final:');
      debugPrint('🔧 Biometric - canCheckBiometrics: $canCheckAfter');
      debugPrint('🔧 Biometric - isDeviceSupported: $isSupported');
      debugPrint('🔧 Biometric - availableBiometrics: $availableBiometrics');
      
      bool allGood = permissionGranted && canCheckAfter && isSupported && availableBiometrics.isNotEmpty;
      
      return {
        'success': allGood,
        'permissionGranted': permissionGranted,
        'canCheckBiometrics': canCheckAfter,
        'isDeviceSupported': isSupported,
        'availableBiometrics': availableBiometrics,
        'errorMessage': errorMessage,
        'message': allGood 
          ? '✅ Permisos biométricos concedidos correctamente'
          : '❌ No se pudieron conceder los permisos biométricos',
      };
      
    } catch (e) {
      debugPrint('🔧 Biometric - Error general solicitando permisos: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error solicitando permisos biométricos',
      };
    }
  }

  // Método para verificar y solicitar permisos biométricos
  static Future<Map<String, dynamic>> checkAndRequestPermissions() async {
    try {
      debugPrint('🔧 Biometric - 🔍 Verificando permisos biométricos...');
      
      // Verificar si podemos usar biometría directamente
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      debugPrint('🔧 Biometric - canCheckBiometrics: $canCheckBiometrics');
      
      final isDeviceSupported = await _auth.isDeviceSupported();
      debugPrint('🔧 Biometric - isDeviceSupported: $isDeviceSupported');
      
      // Verificar tipos disponibles
      List<BiometricType> availableBiometrics = [];
      if (canCheckBiometrics) {
        availableBiometrics = await _auth.getAvailableBiometrics();
        debugPrint('🔧 Biometric - availableBiometrics: $availableBiometrics');
      }
      
      // Estado de configuración de huella
      bool isEnrolled = false;
      if (availableBiometrics.isNotEmpty) {
        // Intentar autenticación para verificar si hay huella configurada
        try {
          await _auth.authenticate(
            localizedReason: 'Verificando configuración biométrica',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: false,
              useErrorDialogs: false,
            ),
          );
          isEnrolled = true;
        } catch (e) {
          // Si falla, puede ser que no hay huella configurada
          debugPrint('🔧 Biometric - Verificación de enroll: ${e.toString()}');
          if (e.toString().contains('NotEnrolled')) {
            isEnrolled = false;
          }
        }
      }
      
      debugPrint('🔧 Biometric - isEnrolled: $isEnrolled');
      
      // Resumen final
      bool allGood = canCheckBiometrics && 
                    isDeviceSupported && 
                    isEnrolled;
      
      String message = allGood 
          ? '✅ Todo configurado correctamente'
          : '❌ Hay problemas con la configuración';
      
      debugPrint('🔧 Biometric - 📋 Resumen: $message');
      
      return {
        'success': allGood,
        'canCheckBiometrics': canCheckBiometrics,
        'isDeviceSupported': isDeviceSupported,
        'availableBiometrics': availableBiometrics,
        'isEnrolled': isEnrolled,
        'message': message,
        'issues': _getPermissionIssues(canCheckBiometrics, isDeviceSupported, isEnrolled),
      };
    } catch (e) {
      debugPrint('🔧 Biometric - Error verificando permisos: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando permisos',
      };
    }
  }
  
  static List<String> _getPermissionIssues(
    bool canCheckBiometrics,
    bool isDeviceSupported,
    bool isEnrolled,
  ) {
    List<String> issues = [];
    
    if (!canCheckBiometrics) {
      issues.add('❌ No se puede verificar biometría');
    }
    
    if (!isDeviceSupported) {
      issues.add('❌ Dispositivo no soporta biometría');
    }
    
    if (!isEnrolled) {
      issues.add('❌ No hay huella configurada');
    }
    
    return issues;
  }
  static Future<Map<String, dynamic>> testAuthentication() async {
    try {
      debugPrint('🔧 Biometric - 🧪 Test básico de autenticación...');
      debugPrint('🔧 Biometric - 🧪 Verificando disponibilidad...');
      
      // Verificar estado primero
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('🔧 Biometric - 🧪 canCheckBiometrics: $canCheck');
      
      final isSupported = await _auth.isDeviceSupported();
      debugPrint('🔧 Biometric - 🧪 isDeviceSupported: $isSupported');
      
      if (canCheck) {
        final availableTypes = await _auth.getAvailableBiometrics();
        debugPrint('🔧 Biometric - 🧪 availableBiometrics: $availableTypes');
      }
      
      debugPrint('🔧 Biometric - 🧪 Iniciando autenticación de prueba...');
      
      final bool result = await _auth.authenticate(
        localizedReason: 'Test de autenticación - Por favor verifica tu identidad',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      
      debugPrint('🔧 Biometric - 🧪 Test resultado: $result');
      return {
        'success': result,
        'error': null,
      };
    } catch (e) {
      debugPrint('🔧 Biometric - 🧪 Test error completo:');
      debugPrint('🔧 Biometric - 🧪 Error: $e');
      debugPrint('🔧 Biometric - 🧪 Type: ${e.runtimeType}');
      debugPrint('🔧 Biometric - 🧪 toString(): ${e.toString()}');
      
      String userMessage = 'Error desconocido';
      
      // Analizar error específico para mensaje amigable
      if (e.toString().contains('NotAvailable')) {
        userMessage = 'Biometría no disponible en este dispositivo';
      } else if (e.toString().contains('NotEnrolled')) {
        userMessage = 'No hay huella configurada. Configúrala en Ajustes > Seguridad';
      } else if (e.toString().contains('LockedOut')) {
        userMessage = 'Demasiados intentos fallidos. Espera 30 segundos';
      } else if (e.toString().contains('PermanentlyLockedOut')) {
        userMessage = 'Dispositivo bloqueado. Reinícialo para continuar';
      } else if (e.toString().contains('PlatformException')) {
        userMessage = 'Error del sistema Android: ${e.toString()}';
      } else if (e.toString().contains('TimeoutException')) {
        userMessage = 'Tiempo de espera agotado. Intenta nuevamente';
      }
      
      return {
        'success': false,
        'error': userMessage,
        'technicalError': e.toString(),
      };
    }
  }

  static Future<bool> authenticateWithCredentials() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Autentícate para continuar',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en authenticateWithCredentials: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('🔧 Biometric - Tipos biométricos disponibles: $biometrics');
      return biometrics;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en getAvailableBiometrics: $e');
      return [];
    }
  }

  static String getBiometricTypeString(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Huella dactilar';
      case BiometricType.iris:
        return 'Escáner de iris';
      case BiometricType.strong:
      case BiometricType.weak:
        return 'Biometría';
      default:
        return 'Biometría';
    }
  }
}
