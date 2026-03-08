import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

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
      
      // Verificar disponibilidad antes de autenticar
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        debugPrint('🔧 Biometric - Dispositivo no soportado');
        return false;
      }
      
      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        debugPrint('🔧 Biometric - No hay biometría configurada');
        return false;
      }
      
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Autentícate para continuar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      
      debugPrint('🔧 Biometric - Autenticación exitosa: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      debugPrint('🔧 Biometric - Error en authenticateWithBiometrics: $e');
      
      // Manejar errores específicos
      if (e.toString().contains('NotAvailable')) {
        debugPrint('🔧 Biometric - Biometría no disponible en este dispositivo');
      } else if (e.toString().contains('NotEnrolled')) {
        debugPrint('🔧 Biometric - No hay huella configurada');
      } else if (e.toString().contains('LockedOut')) {
        debugPrint('🔧 Biometric - Demasiados intentos fallidos, dispositivo bloqueado');
      } else if (e.toString().contains('PermanentlyLockedOut')) {
        debugPrint('🔧 Biometric - Bloqueo permanente, requiere desbloqueo del dispositivo');
      }
      
      return false;
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
