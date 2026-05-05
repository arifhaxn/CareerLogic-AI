import 'experience_model.dart'; // Don't forget to import the new model!

class ResumeModel {
  final String id;
  final String title;
  final String summary;
  final List<ExperienceModel> experiences; // The nested list of jobs
  final List<String> skills; // Skills list from upload/AI
  final List<Map<String, dynamic>> education; // Education entries
  final List<Map<String, dynamic>> projects; // Project entries

  ResumeModel({
    required this.id,
    required this.title,
    this.summary = '',
    this.experiences = const [], // Default to an empty list
    this.skills = const [],
    this.education = const [],
    this.projects = const [],
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    // Backend may use 'experience' (singular) or 'experiences' (plural)
    var expList = json['experience'] as List? ?? json['experiences'] as List? ?? [];
    var skillsList = json['skills'] as List? ?? [];
    var eduList = json['education'] as List? ?? [];
    var projList = json['projects'] as List? ?? [];

    return ResumeModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Resume',
      summary: json['summary'] ?? '',
      // Map the nested JSON list into Dart ExperienceModel objects
      experiences: expList.map((e) => ExperienceModel.fromJson(e)).toList(),
      skills: skillsList.map((s) => s.toString()).toList(),
      education: eduList.map((e) => Map<String, dynamic>.from(e)).toList(),
      projects: projList.map((p) => Map<String, dynamic>.from(p)).toList(),
    );
  }

  /// Convert to JSON for sending to the backend (e.g., /from-upload)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'skills': skills,
      'experience': experiences.map((e) => e.toJson()).toList(),
      'education': education,
      'projects': projects,
    };
  }
}