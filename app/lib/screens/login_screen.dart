import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'readings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      debugPrint('🔧 LoginScreen - Verificando disponibilidad biométrica...');
      
      final canUse = await AuthService.canUseBiometricForLogin();
      debugPrint('🔧 LoginScreen - Puede usar biometría para login: $canUse');
      
      if (mounted) {
        setState(() {
          _useBiometric = canUse;
        });
      }
    } catch (e) {
      debugPrint('🔧 LoginScreen - Error verificando biometría: $e');
    }
  }

  Future<void> _testBiometric() async {
    debugPrint('🔧 LoginScreen - 🧪 Iniciando test de biometría...');
    
    setState(() => _loading = true);
    
    try {
      final result = await BiometricService.testAuthentication();
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🧪 Test biométrico: EXITOSO ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Mostrar error específico
          String errorMessage = result['error'] ?? 'Error desconocido';
          String technicalError = result['technicalError'] ?? '';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🧪 Test biométrico: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Detalles',
                onPressed: () {
                  _showTechnicalDetails(technicalError);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 LoginScreen - Error en test biometric: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧪 Test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkPermissions() async {
    debugPrint('🔧 LoginScreen - 🔐 Verificando y solicitando permisos biométricos...');
    
    setState(() => _loading = true);
    
    try {
      // Primero solicitar permisos activamente
      final permissionResult = await BiometricService.requestBiometricPermissions();
      
      if (mounted) {
        if (permissionResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔐 Permisos biométricos: TODO OK ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Mostrar diálogo con opciones
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Permisos Biométricos'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(permissionResult['message'] ?? 'Error desconocido'),
                  const SizedBox(height: 12),
                  if (permissionResult['errorMessage']?.isNotEmpty == true)
                    Text('Error: ${permissionResult['errorMessage']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Pasos para solucionar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Click en "Solicitar Permisos"'),
                  const Text('2. Permite el acceso cuando Android lo pida'),
                  const Text('3. Configura tu huella si es necesario'),
                  const Text('4. Reinicia la app'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _requestPermissions(); // Solicitar permisos activamente
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Solicitar Permisos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 LoginScreen - Error verificando permisos: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔐 Error verificando permisos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    debugPrint('🔧 LoginScreen - 🚪 Solicitando permisos biométricos activamente...');
    
    setState(() => _loading = true);
    
    try {
      final result = await BiometricService.requestBiometricPermissions();
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔐 ¡Permisos concedidos! Prueba el login biométrico ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔐 No se pudieron conceder los permisos: ${result['errorMessage'] ?? 'Error desconocido'}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 LoginScreen - Error solicitando permisos: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔐 Error solicitando permisos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showTechnicalDetails(String technicalError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles Técnicos'),
        content: SingleChildScrollView(
          child: Text(
            'Error técnico:\n$technicalError\n\n'
            'Posibles soluciones:\n'
            '1. Verifica que tengas huella configurada\n'
            '2. Reinicia el dispositivo\n'
            '3. Limpia cache de la app\n'
            '4. Actualiza Android',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometric() async {
    debugPrint('🔧 LoginScreen - Iniciando autenticación biométrica...');
    
    setState(() => _loading = true);
    
    try {
      final result = await AuthService.authenticateWithBiometric();
      
      if (result['success'] && mounted) {
        debugPrint('🔧 LoginScreen - Autenticación biométrica exitosa');
        
        // Navegar a pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReadingsScreen()),
        );
      } else if (mounted) {
        debugPrint('🔧 LoginScreen - Autenticación biométrica fallida: ${result['error']}');
        
        // Si fue cancelada, ofrecer reintento
        final shouldRetry = await _showRetryDialog(result['error'] ?? 'Error desconocido');
        
        if (shouldRetry) {
          // Reintentar automáticamente
          _authenticateWithBiometric();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Autenticación biométrica fallida'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Reintentar',
                onPressed: _authenticateWithBiometric,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 LoginScreen - Error en autenticación biométrica: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    Map<String, dynamic> result;
    if (_isLogin) {
      result = await AuthService.login(
        _emailController.text,
        _passwordController.text,
        useBiometric: _useBiometric,
      );
    } else {
      result = await AuthService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        useBiometric: _useBiometric,
      );
    }

    setState(() => _loading = false);

    if (result['success']) {
      // Si login exitoso y biometría no estaba habilitada, preguntar si quiere habilitarla
      if (_isLogin && !_useBiometric) {
        final hasBiometric = await AuthService.hasBiometricCredentials();
        if (!hasBiometric) {
          // Preguntar si quiere habilitar biometría
          if (mounted) {
            final shouldEnable = await _showEnableBiometricDialog();
            if (shouldEnable) {
              final enableResult = await AuthService.enableBiometric(
                _emailController.text,
                _passwordController.text,
              );
              if (enableResult['success'] && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Biometría habilitada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        }
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReadingsScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Error')),
        );
      }
    }
  }

  Future<bool> _showRetryDialog(String errorMessage) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.orange),
              SizedBox(width: 8),
              Text('Autenticación Biométrica'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              const SizedBox(height: 12),
              const Text(
                '¿Deseas intentar nuevamente?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Consejo: Mantén tu huella firmemente en el sensor hasta que vibre.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Usar contraseña'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showEnableBiometricDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue),
              SizedBox(width: 8),
              Text('Habilitar Biometría'),
            ],
          ),
          content: const Text(
            '¿Deseas usar tu huella dactilar para iniciar sesión más rápido la próxima vez?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, gracias'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Sí, habilitar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón de autenticación biométrica (si está habilitado y hay sesión guardada)
            if (_useBiometric)
              Column(
                children: [
                  const Text(
                    'Usar autenticación biométrica',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Iniciar con huella'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botón de prueba para diagnóstico
                  TextButton.icon(
                    onPressed: _loading ? null : _testBiometric,
                    icon: const Icon(Icons.bug_report, size: 16),
                    label: const Text('🧪 Test biométrico'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Botón para verificar permisos
                  TextButton.icon(
                    onPressed: _loading ? null : _checkPermissions,
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text('🔐 Verificar permisos'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'O inicia sesión con tus credenciales:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Formulario tradicional
            if (!_isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(_isLogin ? 'Entrar' : 'Registrarse'),
            ),
            const SizedBox(height: 16),
            
            // Opción de habilitar biometría (solo en registro)
            if (!_isLogin)
              StatefulBuilder(
                builder: (context, setState) {
                  return CheckboxListTile(
                    title: const Text('Habilitar autenticación biométrica'),
                    subtitle: const Text('Usa tu huella para iniciar sesión'),
                    value: _useBiometric,
                    onChanged: (value) {
                      setState(() => _useBiometric = value ?? false);
                    },
                  );
                },
              ),
            
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Entra'),
            ),
          ],
        ),
      ),
    );
  }
}
