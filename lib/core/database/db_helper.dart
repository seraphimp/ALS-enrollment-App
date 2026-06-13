import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  // For USB debugging with physical device
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For physical device via USB
      return 'http://192.168.1.100:8000'; // Replace with your computer's IP
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  static const int timeoutSeconds = 10;

  static Future<List<dynamic>> fetchTeachers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/als/api/teachers.php'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        } else {
          throw Exception(data['error'] ?? 'Failed to load teachers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection failed: $e');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> loginTeacher(int teacherId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/als-system/api/teachers/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'teacher_id': teacherId,
              'last_login': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Teacher not found');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection failed: $e');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
