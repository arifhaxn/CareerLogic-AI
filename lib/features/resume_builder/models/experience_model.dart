class ExperienceModel {
  final String id; // Maps to the MongoDB _id for this specific experience block
  final String company;
  final String position;
  final List<String> bullets;

  ExperienceModel({
    required this.id,
    required this.company,
    required this.position,
    required this.bullets,
  });

  // Parse the JSON coming from the backend
  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['_id'] ?? '',
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
    );
  }

  // Convert back to JSON when sending updates to the server[cite: 2]
  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'bullets': bullets,
    };
  }
}