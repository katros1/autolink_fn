class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final String profilePicture;
  final String accountStatus;
  final String token;
  final bool verified;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    required this.profilePicture,
    required this.accountStatus,
    required this.token,
    required this.verified,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['role'] ?? []),
      profilePicture: json['profilePicture'] ?? '',
      accountStatus: json['accountStatus'] ?? '',
      token: json['token'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': roles,
      'profilePicture': profilePicture,
      'accountStatus': accountStatus,
      'token': token,
      'verified': verified,
    };
  }
}