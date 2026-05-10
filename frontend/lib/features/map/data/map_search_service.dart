import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../domain/place_suggestion.dart';
import '../domain/route_preference.dart';

final mapSearchServiceProvider = Provider<MapSearchService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return MapSearchService(client);
});

class MapSearchService {
  MapSearchService(this._client);

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

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final uri = _buildUri('/search', {'query': query});

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw MapSearchException(_extractErrorMessage(response));
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = (data['suggestions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return suggestions.map((Map<String, dynamic> item) {
      return PlaceSuggestion(
        name: item['name'] as String,
        address: item['address'] as String,
        coordinates: LatLng(
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        ),
      );
    }).toList();
  }

  Future<PlaceSuggestion?> reverseGeocode(LatLng point) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
      queryParameters: {
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'format': 'jsonv2',
        'addressdetails': '1',
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'secmap-app/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['display_name'] as String?;
      if (address == null || address.isEmpty) {
        return null;
      }

      final name = _extractNameFromAddress(data);
      return PlaceSuggestion(
        name: name,
        address: address,
        coordinates: point,
      );
    } catch (_) {
      return null;
    }
  }

  String _extractNameFromAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      return 'Unknown Location';
    }

    final nameFields = [
      'amenity',
      'shop',
      'tourism',
      'building',
      'office',
      'city',
      'town',
      'village',
      'suburb',
      'road',
    ];

    for (final field in nameFields) {
      final value = address[field] as String?;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return 'Unknown Location';
  }

  Future<({List<LatLng> points, double distanceMeters, double durationSeconds})>
  fetchRoute({
    required LatLng source,
    required LatLng destination,
    RoutePreference routePreference = RoutePreference.shortest,
  }) async {
    final routePath = routePreference == RoutePreference.safest
        ? '/route/safest'
        : '/route/shortest';
    final uri = _buildUri(routePath);

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'source': {'latitude': source.latitude, 'longitude': source.longitude},
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw MapSearchException(_extractErrorMessage(response));
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final coordinates = (data['points'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final points = coordinates.map((Map<String, dynamic> point) {
      return LatLng(
        (point['latitude'] as num).toDouble(),
        (point['longitude'] as num).toDouble(),
      );
    }).toList();

    return (
      points: points,
      distanceMeters: (data['distanceMeters'] as num).toDouble(),
      durationSeconds: (data['durationSeconds'] as num).toDouble(),
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Fall through to the generic message below.
    }

    if (response.statusCode >= 500) {
      return 'Backend routing service is unavailable right now.';
    }

    if (response.statusCode == 404) {
      return 'Backend route service is not reachable.';
    }

    return 'Unable to complete the map request right now.';
  }
}

class MapSearchException implements Exception {
  const MapSearchException(this.message);

  final String message;
}
