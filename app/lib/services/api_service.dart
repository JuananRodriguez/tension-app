import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/reading.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.68.65:3000';

  static Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: AuthService.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Failed to load users');
  }

  static Future<List<Reading>> getMyReadings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/readings/my'),
      headers: AuthService.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Reading.fromJson(e)).toList();
    }
    throw Exception('Failed to load readings');
  }

  static Future<void> createReading(Reading reading) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/readings'),
      headers: AuthService.authHeaders,
      body: jsonEncode({
        'systolic': reading.systolic,
        'diastolic': reading.diastolic,
        'pulse': reading.pulse,
        'notes': reading.notes,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create reading');
    }
  }

  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: AuthService.authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  static Future<void> deleteReading(int readingId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/readings/$readingId'),
      headers: AuthService.authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete reading');
    }
  }
}
