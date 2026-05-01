class UserModel {
  final String id; // This will map to MongoDB's _id field
  final String name;
  final String email;
  final String token; // The JWT for maintaining the session

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
  });

  // This factory constructor takes the JSON from your friend's MongoDB/Node backend
  // and turns it into a structured Dart object you can use in your UI.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '', // MongoDB defaults to _id
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? '',
    );
  }

  // This converts the Dart object back to JSON if you ever need to send it to the server
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'token': token,
    };
  }
}