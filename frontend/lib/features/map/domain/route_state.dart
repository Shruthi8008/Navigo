import 'package:latlong2/latlong.dart';

import 'place_suggestion.dart';
import 'route_preference.dart';

enum RouteField { source, destination }

class RouteState {
  const RouteState({
    this.source,
    this.destination,
    this.sourceLabel = '',
    this.destinationLabel = '',
    this.activeField = RouteField.destination,
    this.suggestions = const [],
    this.routePoints = const [],
    this.isSearching = false,
    this.isRouting = false,
    this.errorMessage,
    this.distanceMeters,
    this.durationSeconds,
    this.useCurrentLocationAsSource = true,
    this.routePreference = RoutePreference.shortest,
  });

  final LatLng? source;
  final LatLng? destination;
  final String sourceLabel;
  final String destinationLabel;
  final RouteField activeField;
  final List<PlaceSuggestion> suggestions;
  final List<LatLng> routePoints;
  final bool isSearching;
  final bool isRouting;
  final String? errorMessage;
  final double? distanceMeters;
  final double? durationSeconds;
  final bool useCurrentLocationAsSource;
  final RoutePreference routePreference;

  bool get hasRoute => routePoints.isNotEmpty;

  RouteState copyWith({
    LatLng? source,
    bool clearSource = false,
    LatLng? destination,
    bool clearDestination = false,
    String? sourceLabel,
    String? destinationLabel,
    RouteField? activeField,
    List<PlaceSuggestion>? suggestions,
    List<LatLng>? routePoints,
    bool clearRoute = false,
    bool? isSearching,
    bool? isRouting,
    String? errorMessage,
    bool clearError = false,
    double? distanceMeters,
    bool clearDistance = false,
    double? durationSeconds,
    bool clearDuration = false,
    bool? useCurrentLocationAsSource,
    RoutePreference? routePreference,
  }) {
    return RouteState(
      source: clearSource ? null : source ?? this.source,
      destination: clearDestination ? null : destination ?? this.destination,
      sourceLabel: clearSource ? '' : sourceLabel ?? this.sourceLabel,
      destinationLabel: clearDestination
          ? ''
          : destinationLabel ?? this.destinationLabel,
      activeField: activeField ?? this.activeField,
      suggestions: suggestions ?? this.suggestions,
      routePoints: clearRoute ? const [] : routePoints ?? this.routePoints,
      isSearching: isSearching ?? this.isSearching,
      isRouting: isRouting ?? this.isRouting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      distanceMeters: clearDistance
          ? null
          : distanceMeters ?? this.distanceMeters,
      durationSeconds: clearDuration
          ? null
          : durationSeconds ?? this.durationSeconds,
      useCurrentLocationAsSource:
          useCurrentLocationAsSource ?? this.useCurrentLocationAsSource,
      routePreference: routePreference ?? this.routePreference,
    );
  }
}
