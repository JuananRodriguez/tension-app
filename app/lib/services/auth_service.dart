import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.68.65:3000';
  static String? _token;
  static User? _currentUser;

  static String? get token => _token;
  static User? get currentUser => _currentUser;

  static Future<void> setAuth(String token, User user) async {
    _token = token;
    _currentUser = user;
    
    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
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

  static Future<void> clearAuth() async {
    _token = null;
    _currentUser = null;
    
    // Limpiar SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static bool get isAuthenticated => _token != null;
  static bool get isAdmin => _currentUser?.isAdmin ?? false;

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setAuth(data['token'], User.fromJson(data['user']));
      return {'success': true};
    }
    return {'success': false, 'error': response.body};
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setAuth(data['token'], User.fromJson(data['user']));
      return {'success': true};
    }
    return {'success': false, 'error': 'Invalid credentials'};
  }

  static Future<void> logout() async {
    await clearAuth();
  }
}
