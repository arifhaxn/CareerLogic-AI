import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants.dart';
import '../models/resume_model.dart';

/// Service class for all 7 AI-powered endpoints.
class AiService {
  final String _baseUrl = AppConstants.aiUrl;

  // ──────────────────────────────────────────────
  // 1. POST /api/ai/generate-summary
  //    Generate a professional summary using AI
  // ──────────────────────────────────────────────
  Future<String> generateSummary({
    required String token,
    required String jobTitle,
    required String experienceLevel,
    required List<String> skills,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jobTitle': jobTitle,
          'experienceLevel': experienceLevel,
          'skills': skills,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['summary'] ?? '';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to generate summary.');
      }
    } catch (e) {
      throw Exception('AI Summary Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 2. POST /api/ai/tailor-resume
  //    AI improves resume for a job description
  //    Returns suggestions — does NOT save to DB
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> tailorResume({
    required String token,
    required String resumeId,
    required String jobDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tailor-resume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'resumeId': resumeId,
          'jobDescription': jobDescription,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to tailor resume.');
      }
    } catch (e) {
      throw Exception('AI Tailor Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 3. POST /api/ai/apply-tailor
  //    Apply AI suggestions and save to DB
  // ──────────────────────────────────────────────
  Future<ResumeModel> applyTailorChanges({
    required String token,
    required String resumeId,
    required String summary,
    required List<Map<String, dynamic>> experiences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/apply-tailor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'resumeId': resumeId,
          'summary': summary,
          'experiences': experiences,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to apply AI changes.');
      }
    } catch (e) {
      throw Exception('Apply Tailor Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 4. POST /api/ai/analyze-resume
  //    ATS-style analysis: score, missing keywords, suggestions
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeResume({
    required String token,
    required String resumeId,
    required String jobDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-resume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'resumeId': resumeId,
          'jobDescription': jobDescription,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { score, missingKeywords[], suggestions[] }
        return data['data'] ?? data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to analyze resume.');
      }
    } catch (e) {
      throw Exception('ATS Analysis Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 5. POST /api/ai/full-analysis
  //    🚀 BEST FEATURE — before/after scores + improvements
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> fullAnalysis({
    required String token,
    required String resumeId,
    required String jobDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/full-analysis'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'resumeId': resumeId,
          'jobDescription': jobDescription,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { before: { score }, after: { score }, improvements: { summary, experiences[] } }
        return data['data'] ?? data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to run full analysis.');
      }
    } catch (e) {
      throw Exception('Full Analysis Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 6. POST /api/ai/upload-resume
  //    Upload PDF → AI parses into structured data
  //    Body is FORM-DATA (not JSON)
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadResumePdf({
    required String token,
    required File pdfFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload-resume'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'resume', // Key name expected by backend
          pdfFile.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { title, summary, skills[], experience[], education[], projects[] }
        return data['data'] ?? data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to upload resume.');
      }
    } catch (e) {
      throw Exception('Upload Resume Error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 7. POST /api/ai/from-upload
  //    Save parsed AI data into the database
  // ──────────────────────────────────────────────
  Future<ResumeModel> saveFromUpload({
    required String token,
    required Map<String, dynamic> parsedData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/from-upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(parsedData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ResumeModel.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save uploaded resume.');
      }
    } catch (e) {
      throw Exception('Save Upload Error: $e');
    }
  }
}
