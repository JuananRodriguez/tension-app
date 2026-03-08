import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/reading.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.68.65:3000';

  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Failed to load users');
  }

  static Future<User> createUser(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create user');
  }

  static Future<List<Reading>> getReadings(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/readings/$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Reading.fromJson(e)).toList();
    }
    throw Exception('Failed to load readings');
  }

  static Future<void> createReading(Reading reading) async {
    final response = await http.post(
      Uri.parse('$baseUrl/readings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reading.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create reading');
    }
  }

  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  static Future<void> deleteReading(int readingId) async {
    final response = await http.delete(Uri.parse('$baseUrl/readings/$readingId/delete'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete reading');
    }
  }
}
