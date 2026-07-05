enum AuthRole {
  user,
  admin,
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  bool get isComplete => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

class AuthSession {
  const AuthSession({
    required this.user,
    this.tokens,
  });

  final AuthUser user;
  final AuthTokens? tokens;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.username,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? username;
  final AuthRole role;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      role: _roleFromJson(json['role']),
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.user,
    this.accessToken,
    this.refreshToken,
  });

  final AuthUser user;
  final String? accessToken;
  final String? refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return AuthResponse(
      user: AuthUser.fromJson(
        userJson is Map<String, dynamic> ? userJson : const <String, dynamic>{},
      ),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

class ApiMessageResponse {
  const ApiMessageResponse({
    required this.message,
    this.accessToken,
    this.refreshToken,
  });

  final String message;
  final String? accessToken;
  final String? refreshToken;

  factory ApiMessageResponse.fromJson(Map<String, dynamic> json) {
    return ApiMessageResponse(
      message: json['message'] as String? ?? '',
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

class LoginPayload {
  const LoginPayload({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterPayload {
  const RegisterPayload({
    required this.email,
    required this.password,
    this.username,
  });

  final String email;
  final String password;
  final String? username;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (username != null && username!.isNotEmpty) 'username': username,
    };
  }
}

class ForgotPasswordPayload {
  const ForgotPasswordPayload({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class ResetPasswordPayload {
  const ResetPasswordPayload({
    required this.token,
    required this.password,
  });

  final String token;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'password': password,
    };
  }
}

class VerifyEmailPayload {
  const VerifyEmailPayload({
    this.token,
    this.code,
  });

  final String? token;
  final String? code;

  Map<String, dynamic> toJson() {
    return {
      if (token != null && token!.isNotEmpty) 'token': token,
      if (code != null && code!.isNotEmpty) 'code': code,
    };
  }
}

AuthRole _roleFromJson(Object? value) {
  return switch (value) {
    'ADMIN' => AuthRole.admin,
    _ => AuthRole.user,
  };
}

DateTime? _dateFromJson(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
