import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers/auth_provider.dart';
import '../data/map_community_service.dart';
import '../domain/community_comment.dart';
import '../domain/community_place_state.dart';
import '../domain/place_safety_summary.dart';
import '../domain/place_suggestion.dart';

final communityControllerProvider =
    NotifierProvider<CommunityController, CommunityPlaceState>(
      CommunityController.new,
    );

class CommunityController extends Notifier<CommunityPlaceState> {
  @override
  CommunityPlaceState build() => const CommunityPlaceState();

  void clearPlace() {
    state = state.copyWith(
      clearSelectedPlace: true,
      clearPlaceSafetySummary: true,
      clearRoadSafetySummary: true,
      clearUserPlaceRating: true,
      comments: const [],
      isFavorite: false,
      clearTappedCoordinates: true,
      tappedLocationComments: const [],
    );
  }

  Future<void> loadPlaceContext({
    PlaceSuggestion? place,
    List<LatLng> routePoints = const [],
    LatLng? tappedCoordinates,
  }) async {
    state = state.copyWith(
      selectedPlace: place,
      isLoading: true,
      clearError: true,
      tappedCoordinates: tappedCoordinates,
      clearTappedCoordinates: tappedCoordinates == null,
    );

    try {
      PlaceSafetySummary? placeSummary;
      Map<String, dynamic>? userRating;
      if (place != null) {
        final session = ref.read(authProvider).valueOrNull;
        placeSummary = await ref
            .read(mapCommunityServiceProvider)
            .getPlaceSafetySummary(
              latitude: place.coordinates.latitude,
              longitude: place.coordinates.longitude,
            );
        if (session != null) {
          userRating = await ref
              .read(mapCommunityServiceProvider)
              .getUserPlaceRating(
                session: session,
                latitude: place.coordinates.latitude,
                longitude: place.coordinates.longitude,
              );
        }
      }

      final roadSummary = routePoints.length < 2
          ? state.roadSafetySummary
          : await ref
                .read(mapCommunityServiceProvider)
                .getRoadSafetySummary(
                  routePoints: routePoints
                      .map(
                        (point) => {
                          'latitude': point.latitude,
                          'longitude': point.longitude,
                        },
                      )
                      .toList(),
                );

      List<CommunityComment> comments = [];
      List<CommunityComment> tappedComments = [];
      if (place != null) {
        comments = await ref
            .read(mapCommunityServiceProvider)
            .getComments(
              targetType: 'place',
              targetKey: _placeKey(
                place.coordinates.latitude,
                place.coordinates.longitude,
              ),
            );
      } else if (tappedCoordinates != null) {
        final nearbyComments = await ref
            .read(mapCommunityServiceProvider)
            .getCommentsNearLocation(
              latitude: tappedCoordinates.latitude,
              longitude: tappedCoordinates.longitude,
            );
        tappedComments = nearbyComments;
      }

      var isFavorite = false;
      if (place != null) {
        final session = ref.read(authProvider).valueOrNull;
        if (session != null) {
          isFavorite = await ref
              .read(mapCommunityServiceProvider)
              .getIsFavorite(
                session: session,
                latitude: place.coordinates.latitude,
                longitude: place.coordinates.longitude,
              );
        }
      }

      state = state.copyWith(
        placeSafetySummary: placeSummary ?? state.placeSafetySummary,
        roadSafetySummary: roadSummary,
        comments: comments,
        isFavorite: isFavorite,
        isLoading: false,
        userPlaceRating: userRating,
        tappedLocationComments: tappedComments,
      );
    } on MapCommunityException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load community details right now.',
      );
    }
  }

  Future<void> toggleFavorite() async {
    final place = state.selectedPlace;
    final session = ref.read(authProvider).valueOrNull;
    if (place == null || session == null) {
      state = state.copyWith(errorMessage: 'Please log in to save favorites.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (state.isFavorite) {
        await ref
            .read(mapCommunityServiceProvider)
            .removeFavorite(
              session: session,
              latitude: place.coordinates.latitude,
              longitude: place.coordinates.longitude,
            );
      } else {
        await ref
            .read(mapCommunityServiceProvider)
            .addFavorite(
              session: session,
              placeName: place.name,
              address: place.address,
              latitude: place.coordinates.latitude,
              longitude: place.coordinates.longitude,
            );
      }
      state = state.copyWith(
        isFavorite: !state.isFavorite,
        isSubmitting: false,
      );
    } on MapCommunityException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    }
  }

  Future<void> addPlaceRating({required String rating, String? comment}) async {
    final place = state.selectedPlace;
    final session = ref.read(authProvider).valueOrNull;
    if (place == null || session == null) {
      state = state.copyWith(errorMessage: 'Please log in to rate places.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref
          .read(mapCommunityServiceProvider)
          .addPlaceRating(
            session: session,
            placeName: place.name,
            address: place.address,
            latitude: place.coordinates.latitude,
            longitude: place.coordinates.longitude,
            rating: rating,
            comment: comment,
          );

      await loadPlaceContext(place: place);
      state = state.copyWith(isSubmitting: false);
    } on MapCommunityException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    }
  }

  Future<void> addRoadRating({
    required String rating,
    required List<LatLng> routePoints,
    String? comment,
  }) async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) {
      state = state.copyWith(errorMessage: 'Please log in to rate routes.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final summary = await ref
          .read(mapCommunityServiceProvider)
          .addRoadRating(
            session: session,
            routePoints: routePoints
                .map(
                  (point) => {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                )
                .toList(),
            rating: rating,
            comment: comment,
          );
      state = state.copyWith(roadSafetySummary: summary, isSubmitting: false);
    } on MapCommunityException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    }
  }

  Future<void> addComment({
    required String targetType,
    required String targetKey,
    required String comment,
  }) async {
    final place = state.selectedPlace;
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) {
      state = state.copyWith(errorMessage: 'Please log in to post comments.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref
          .read(mapCommunityServiceProvider)
          .addComment(
            session: session,
            targetType: targetType,
            targetKey: targetKey,
            comment: comment,
            placeName: place?.name,
            address: place?.address,
            latitude: place?.coordinates.latitude,
            longitude: place?.coordinates.longitude,
          );
      if (place != null) {
        final comments = await ref
            .read(mapCommunityServiceProvider)
            .getComments(targetType: targetType, targetKey: targetKey);
        state = state.copyWith(comments: comments, isSubmitting: false);
      } else {
        state = state.copyWith(isSubmitting: false);
      }
    } on MapCommunityException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    }
  }

  String routeCommentKey(List<LatLng> routePoints) {
    return routePoints
        .map(
          (point) =>
              '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}',
        )
        .join('|');
  }

  String placeCommentKey() {
    final place = state.selectedPlace;
    if (place == null) {
      return '';
    }
    return _placeKey(place.coordinates.latitude, place.coordinates.longitude);
  }

  String _placeKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
  }
}
