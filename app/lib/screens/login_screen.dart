import 'package:flutter/material.dart';
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Autenticación biométrica fallida'),
            backgroundColor: Colors.red,
          ),
        );
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
