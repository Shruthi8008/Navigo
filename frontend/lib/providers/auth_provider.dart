import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _authStorageKey = 'auth_session';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_authStorageKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(rawSession) as Map<String, dynamic>;
      return AuthSession.fromJson(json);
    } catch (_) {
      await preferences.remove(_authStorageKey);
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );

      final session = AuthSession.fromJson(response);
      await _persistSession(session);
      return session;
    });
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _post(
        '/auth/signup',
        body: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final session = AuthSession.fromJson(response);
      await _persistSession(session);
      return session;
    });
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_authStorageKey);
    state = const AsyncData(null);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final client = http.Client();
    try {
      final response = await client.post(
        _buildUri(path),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          throw AuthException(detail);
        }
        throw const AuthException('Authentication request failed.');
      }

      return decoded;
    } catch (error) {
      if (error is AuthException) {
        rethrow;
      }
      throw const AuthException(
        'Unable to connect to the authentication service.',
      );
    } finally {
      client.close();
    }
  }

  Uri _buildUri(String path) {
    final configuredBaseUrl = dotenv.env['BACKEND_BASE_URL']?.trim() ?? '';
    if (configuredBaseUrl.isNotEmpty) {
      final baseUri = Uri.parse(configuredBaseUrl);
      return baseUri.replace(path: '${baseUri.path}$path');
    }

    if (kIsWeb) {
      return Uri.http('localhost:8000', path);
    }

    return Uri.http('10.0.2.2:8000', path);
  }

  Future<void> _persistSession(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_authStorageKey, jsonEncode(session.toJson()));
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'user': user.toJson(),
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final int id;
  final String fullName;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'email': email};
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
