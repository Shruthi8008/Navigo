import 'package:latlong2/latlong.dart';

import 'community_comment.dart';
import 'place_safety_summary.dart';
import 'place_suggestion.dart';

class CommunityPlaceState {
  const CommunityPlaceState({
    this.selectedPlace,
    this.placeSafetySummary,
    this.roadSafetySummary,
    this.comments = const [],
    this.isFavorite = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.userPlaceRating,
    this.tappedCoordinates,
    this.tappedLocationComments = const [],
  });

  final PlaceSuggestion? selectedPlace;
  final PlaceSafetySummary? placeSafetySummary;
  final PlaceSafetySummary? roadSafetySummary;
  final List<CommunityComment> comments;
  final bool isFavorite;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, dynamic>? userPlaceRating;
  final LatLng? tappedCoordinates;
  final List<CommunityComment> tappedLocationComments;

  bool get hasUserRating => userPlaceRating != null;
  bool get isTappedLocation => tappedCoordinates != null && selectedPlace == null;
  bool get hasTappedLocationComments => tappedLocationComments.isNotEmpty;

  CommunityPlaceState copyWith({
    PlaceSuggestion? selectedPlace,
    bool clearSelectedPlace = false,
    PlaceSafetySummary? placeSafetySummary,
    bool clearPlaceSafetySummary = false,
    PlaceSafetySummary? roadSafetySummary,
    bool clearRoadSafetySummary = false,
    List<CommunityComment>? comments,
    bool? isFavorite,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? userPlaceRating,
    bool clearUserPlaceRating = false,
    LatLng? tappedCoordinates,
    bool clearTappedCoordinates = false,
    List<CommunityComment>? tappedLocationComments,
  }) {
    return CommunityPlaceState(
      selectedPlace: clearSelectedPlace
          ? null
          : selectedPlace ?? this.selectedPlace,
      placeSafetySummary: clearPlaceSafetySummary
          ? null
          : placeSafetySummary ?? this.placeSafetySummary,
      roadSafetySummary: clearRoadSafetySummary
          ? null
          : roadSafetySummary ?? this.roadSafetySummary,
      comments: comments ?? this.comments,
      isFavorite: isFavorite ?? this.isFavorite,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      userPlaceRating: clearUserPlaceRating
          ? null
          : userPlaceRating ?? this.userPlaceRating,
      tappedCoordinates: clearTappedCoordinates
          ? null
          : tappedCoordinates ?? this.tappedCoordinates,
      tappedLocationComments: tappedLocationComments ?? this.tappedLocationComments,
    );
  }
}
