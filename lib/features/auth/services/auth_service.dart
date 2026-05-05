import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'https://careerlogicai.onrender.com/api/auth';

  // CHANGED: Now returns a Map to capture the token AND user profile
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.headers['content-type']?.contains('text/html') == true) {
        throw Exception('Server returned HTML. Check endpoint URL or Render status.');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          // This returns the {"token": "...", "user": {...}} object
          return decoded['data']; 
        } else {
          throw Exception('Login failed.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // CHANGED: Now returns a Map here as well
  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.headers['content-type']?.contains('text/html') == true) {
        throw Exception('Server returned HTML. Check endpoint URL or Render status.');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'];
        } else {
          throw Exception('Registration failed.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> logout() async {}
}