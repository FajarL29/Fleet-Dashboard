class AuthUser {
  const AuthUser({
    required this.userId,
    required this.username,
    required this.fullname,
    required this.email,
    this.role,
    this.status,
  });

  final String userId;
  final String username;
  final String fullname;
  final String email;
  final String? role;
  final String? status;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id']?.toString().trim() ?? '';
    final username = json['username']?.toString().trim() ?? '';
    if (userId.isEmpty || username.isEmpty) {
      throw const FormatException('Authentication user is incomplete');
    }

    return AuthUser(
      userId: userId,
      username: username,
      fullname: json['fullname']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
      role: _optionalString(json['role']),
      status: _optionalString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'username': username,
      'fullname': fullname,
      'email': email,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
    };
  }
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
