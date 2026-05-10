import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../providers/auth_provider.dart';
import '../domain/community_comment.dart';
import '../domain/place_safety_summary.dart';

final mapCommunityServiceProvider = Provider<MapCommunityService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return MapCommunityService(client);
});

class MapCommunityService {
  MapCommunityService(this._client);

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final configuredBaseUrl = dotenv.env['BACKEND_BASE_URL']?.trim() ?? '';
    if (configuredBaseUrl.isNotEmpty) {
      final baseUri = Uri.parse(configuredBaseUrl);
      return baseUri.replace(
        path: '${baseUri.path}$path',
        queryParameters: queryParameters,
      );
    }

    if (kIsWeb) {
      return Uri.http('localhost:8000', path, queryParameters);
    }

    return Uri.http('10.0.2.2:8000', path, queryParameters);
  }

  Future<PlaceSafetySummary> getPlaceSafetySummary({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.get(
      _buildUri('/community/place-ratings', {
        'latitude': '$latitude',
        'longitude': '$longitude',
      }),
      headers: {'Accept': 'application/json'},
    );

    return _decodeSummary(response);
  }

  Future<PlaceSafetySummary> getRoadSafetySummary({
    required List<Map<String, double>> routePoints,
  }) async {
    final response = await _client.post(
      _buildUri('/community/road-ratings/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'routePoints': routePoints}),
    );

    return _decodeSummary(response);
  }

  Future<PlaceSafetySummary> addRoadRating({
    required AuthSession session,
    required List<Map<String, double>> routePoints,
    required String rating,
    String? comment,
  }) async {
    final response = await _client.post(
      _buildUri('/community/road-ratings'),
      headers: _authHeaders(session),
      body: jsonEncode({
        'routePoints': routePoints,
        'rating': rating,
        'comment': comment,
      }),
    );

    return _decodeSummary(response);
  }

  Future<PlaceSafetySummary> addPlaceRating({
    required AuthSession session,
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
    required String rating,
    String? comment,
  }) async {
    final existingRating = await getUserPlaceRating(
      session: session,
      latitude: latitude,
      longitude: longitude,
    );

    if (existingRating != null) {
      return updatePlaceRating(
        session: session,
        ratingId: existingRating['id'] as int,
        rating: rating,
        comment: comment,
      );
    }

    final response = await _client.post(
      _buildUri('/community/place-ratings'),
      headers: _authHeaders(session),
      body: jsonEncode({
        'placeName': placeName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'comment': comment,
      }),
    );

    return _decodeSummary(response);
  }

  Future<Map<String, dynamic>?> getUserPlaceRating({
    required AuthSession session,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.get(
      _buildUri('/community/place-ratings/me'),
      headers: _authHeaders(session),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ratings = (data['ratings'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();

    if (ratings == null) return null;

    for (final rating in ratings) {
      final lat = (rating['latitude'] as num).toDouble();
      final lng = (rating['longitude'] as num).toDouble();
      if ((lat - latitude).abs() < 0.00001 && (lng - longitude).abs() < 0.00001) {
        return rating;
      }
    }
    return null;
  }

  Future<PlaceSafetySummary> updatePlaceRating({
    required AuthSession session,
    required int ratingId,
    required String rating,
    String? comment,
  }) async {
    final response = await _client.put(
      _buildUri('/community/place-ratings/$ratingId'),
      headers: _authHeaders(session),
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    return _decodeSummary(response);
  }

  Future<List<CommunityComment>> getComments({
    required String targetType,
    required String targetKey,
  }) async {
    final response = await _client.get(
      _buildUri('/community/comments', {
        'target_type': targetType,
        'target_key': targetKey,
      }),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final comments = (data['comments'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return comments.map(CommunityComment.fromJson).toList();
  }

  Future<List<CommunityComment>> getCommentsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 0.5,
  }) async {
    final response = await _client.get(
      _buildUri('/community/comments/nearby', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'radius_km': '$radiusKm',
      }),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        return [];
      }
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final commentsList = data['comments'];
    if (commentsList == null) {
      return [];
    }
    final comments = (commentsList as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return comments.map(CommunityComment.fromJson).toList();
  }

  Future<List<CommunityComment>> getMyComments({
    required AuthSession session,
  }) async {
    final response = await _client.get(
      _buildUri('/community/comments/me'),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        return [];
      }
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final commentsList = data['comments'];
    if (commentsList == null) {
      return [];
    }
    final comments = (commentsList as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return comments.map(CommunityComment.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> getMyFavorites({
    required AuthSession session,
  }) async {
    final response = await _client.get(
      _buildUri('/community/favorites'),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        return [];
      }
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['favorites'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> addComment({
    required AuthSession session,
    required String targetType,
    required String targetKey,
    required String comment,
    String? placeName,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    await _authorizedPost(
      session: session,
      path: '/community/comments',
      body: {
        'targetType': targetType,
        'targetKey': targetKey,
        'comment': comment,
        'placeName': placeName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<bool> getIsFavorite({
    required AuthSession session,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.get(
      _buildUri('/community/favorites'),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final favorites = (data['favorites'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return favorites.any(
      (item) =>
          (item['latitude'] as num).toDouble() == latitude &&
          (item['longitude'] as num).toDouble() == longitude,
    );
  }

  Future<void> addFavorite({
    required AuthSession session,
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _authorizedPost(
      session: session,
      path: '/community/favorites',
      body: {
        'placeName': placeName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> removeFavorite({
    required AuthSession session,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.delete(
      _buildUri('/community/favorites', {
        'latitude': '$latitude',
        'longitude': '$longitude',
      }),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }
  }

  Future<void> removeFavoriteById({
    required AuthSession session,
    required int id,
  }) async {
    final response = await _client.delete(
      _buildUri('/community/favorites/$id'),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }
  }

  Future<void> deleteComment({
    required AuthSession session,
    required int commentId,
  }) async {
    final response = await _client.delete(
      _buildUri('/community/comments/$commentId'),
      headers: _authHeaders(session),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }
  }

  Future<void> _authorizedPost({
    required AuthSession session,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _authHeaders(session),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }
  }

  Map<String, String> _authHeaders(AuthSession session) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': '${session.tokenType} ${session.accessToken}',
    };
  }

  PlaceSafetySummary _decodeSummary(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapCommunityException(_extractErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PlaceSafetySummary.fromJson(data);
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    return 'Unable to complete the community request right now.';
  }
}

class MapCommunityException implements Exception {
  const MapCommunityException(this.message);

  final String message;
}
