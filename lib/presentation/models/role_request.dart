class RoleRequest {
  final String requestId;
  final String names;
  final String userEmail;
  final String profilePic;
  final String requestedRole;
  final String status;

  RoleRequest({
    required this.requestId,
    required this.names,
    required this.userEmail,
    required this.profilePic,
    required this.requestedRole,
    required this.status,
  });

  factory RoleRequest.fromJson(Map<String, dynamic> json) {
    return RoleRequest(
      requestId: json['requestId'] ?? '',
      names: json['names'] ?? '',
      userEmail: json['userEmail'] ?? '',
      profilePic: json['profilePic'] ?? '',
      requestedRole: json['requestedRole'] ?? '',
      status: json['status'] ?? '',
    );
  }
}