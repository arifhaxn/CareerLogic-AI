import 'dart:convert';
import '../models/experience_model.dart';
import 'package:http/http.dart' as http;
import '../models/resume_model.dart';

class ResumeService {
  final String baseUrl = 'https://careerlogicai.onrender.com/api/resumes';

  Future<List<ResumeModel>> getAllResumes(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> resumesJson = data['data'] ?? [];
        return resumesJson.map((json) => ResumeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load resumes (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ResumeModel> createResume(String token, String title) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'title': title, 
          'personalInfo': {
            'name': '',
            'email': '',
            'phone': '',
            'location': ''
          }
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create resume (${response.statusCode})');
      }
    } catch (e) {
      rethrow; 
    }
  }

  // GET /api/resumes/:id - Fetch a single resume with all its experiences
  Future<ResumeModel> getResumeById(String token, String resumeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${resumeId.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load resume (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // PATCH/PUT /api/resumes/:id - Update the main title, summary, and personalInfo
  Future<ResumeModel> updateResumeInfo(String token, String resumeId, String title, String summary) async {
    try {
      final body = jsonEncode({
        'title': title,
        'summary': summary,
        'personalInfo': {
          'name': '',
          'email': '',
          'phone': '',
          'location': ''
        }
      });
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Try PATCH /api/resumes/:id
      var response = await http.patch(
        Uri.parse('$baseUrl/${resumeId.trim()}'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 20));

      // 2. Fallback to PUT /api/resumes/:id if 404
      if (response.statusCode == 404) {
        response = await http.put(
          Uri.parse('$baseUrl/${resumeId.trim()}'),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 20));
      }

      // 3. Fallback to PUT /api/resumes/update/:id if still 404
      if (response.statusCode == 404) {
        response = await http.put(
          Uri.parse('$baseUrl/update/${resumeId.trim()}'),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 20));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        try {
          final errorData = jsonDecode(errorBody);
          throw Exception(errorData['message'] ?? 'Failed to update resume (${response.statusCode})');
        } catch (_) {
          throw Exception('Failed to update resume (${response.statusCode}): $errorBody');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- EXPERIENCE CRUD ---

  // POST /api/resumes/:id/experience - Add a new job
  Future<ResumeModel> addExperience(String token, String resumeId, ExperienceModel experience) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/${resumeId.trim()}/experience'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(experience.toJson()),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']); 
      } else {
        final errorBody = response.body;
        try {
          final errorData = jsonDecode(errorBody);
          throw Exception(errorData['message'] ?? 'Failed to add experience (${response.statusCode})');
        } catch (_) {
          throw Exception('Failed to add experience (${response.statusCode}): $errorBody');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // DELETE /api/resumes/:id - Delete a resume entirely
  Future<void> deleteResume(String token, String resumeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/${resumeId.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete resume (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // PUT /api/resumes/:id/experience/:expId - Update an existing job
  Future<ResumeModel> updateExperience(
    String token, String resumeId, String expId, ExperienceModel experience,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${resumeId.trim()}/experience/${expId.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(experience.toJson()),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update experience (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // DELETE /api/resumes/:id/experience/:expId - Remove a job
  Future<ResumeModel> deleteExperience(String token, String resumeId, String expId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/${resumeId.trim()}/experience/${expId.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to delete experience (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }
}