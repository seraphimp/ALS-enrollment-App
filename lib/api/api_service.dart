import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'R';

  static Future<Map<String, dynamic>> getBarangays() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/barangays'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load barangays');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> generateStudentId() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generate-student-id'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate student ID');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCityZipCodes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/city-zip-codes'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load city ZIP codes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getTeachers({int? barangayId}) async {
    try {
      String url = '$baseUrl/teachers';
      if (barangayId != null) {
        url += '?barangay_id=$barangayId';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load teachers');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> enrollStudent(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enroll'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to enroll student: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
