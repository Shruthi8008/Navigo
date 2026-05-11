import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/map_search_service.dart';
import '../domain/place_suggestion.dart';
import '../domain/route_preference.dart';
import '../domain/route_state.dart';

final routeControllerProvider = NotifierProvider<RouteController, RouteState>(
  RouteController.new,
);

class RouteController extends Notifier<RouteState> {
  @override
  RouteState build() => const RouteState();

  void setActiveField(RouteField field) {
    state = state.copyWith(activeField: field, clearError: true);
  }

  Future<void> searchPlaces({
    required RouteField field,
    required String query,
  }) async {
    setActiveField(field);

    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      state = state.copyWith(
        suggestions: const [],
        isSearching: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      suggestions: const [],
      clearError: true,
    );

    try {
      final suggestions = await ref
          .read(mapSearchServiceProvider)
          .searchPlaces(trimmedQuery);
      state = state.copyWith(suggestions: suggestions, isSearching: false);
    } on MapSearchException catch (error) {
      state = state.copyWith(isSearching: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Unable to search places right now.',
      );
    }
  }

  Future<void> selectSuggestion({
    required RouteField field,
    required PlaceSuggestion suggestion,
    LatLng? currentLocation,
    RoutePreference routePreference = RoutePreference.shortest,
  }) async {
    if (field == RouteField.source) {
      state = state.copyWith(
        source: suggestion.coordinates,
        sourceLabel: suggestion.address,
        useCurrentLocationAsSource: false,
        suggestions: const [],
        clearError: true,
      );
    } else {
      state = state.copyWith(
        destination: suggestion.coordinates,
        destinationLabel: suggestion.address,
        suggestions: const [],
        clearError: true,
      );
    }

    if (field == RouteField.destination &&
        state.source == null &&
        currentLocation != null) {
      state = state.copyWith(
        source: currentLocation,
        sourceLabel: 'Current location',
        useCurrentLocationAsSource: true,
      );
    }

    await buildRoute(routePreference: routePreference);
  }

  Future<void> useCurrentLocationAsSource(
    LatLng? currentLocation, {
    bool rebuildRoute = false,
  }) async {
    if (currentLocation == null) {
      state = state.copyWith(
        errorMessage: 'Current location is not available yet.',
      );
      return;
    }

    state = state.copyWith(
      source: currentLocation,
      sourceLabel: 'Current location',
      useCurrentLocationAsSource: true,
      clearError: true,
    );

    if (rebuildRoute && state.destination != null) {
      await buildRoute();
    }
  }

  Future<void> buildRoute({RoutePreference? routePreference}) async {
    if (state.source == null || state.destination == null) {
      return;
    }

    final selectedPreference = routePreference ?? state.routePreference;

    state = state.copyWith(
      isRouting: true,
      clearError: true,
      clearRoute: true,
      clearDistance: true,
      clearDuration: true,
      routePreference: selectedPreference,
    );

    try {
      final route = await ref
          .read(mapSearchServiceProvider)
          .fetchRoute(
            source: state.source!,
            destination: state.destination!,
            routePreference: selectedPreference,
          );
      state = state.copyWith(
        isRouting: false,
        routePoints: route.points,
        distanceMeters: route.distanceMeters,
        durationSeconds: route.durationSeconds,
        routePreference: selectedPreference,
      );
    } on MapSearchException catch (error) {
      state = state.copyWith(isRouting: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isRouting: false,
        errorMessage: 'Unable to draw a route right now.',
      );
    }
  }

  void clearField(RouteField field) {
    if (field == RouteField.source) {
      state = state.copyWith(
        clearSource: true,
        clearRoute: true,
        clearDistance: true,
        clearDuration: true,
        useCurrentLocationAsSource: false,
      );
      return;
    }

    state = state.copyWith(
      clearDestination: true,
      suggestions: const [],
      clearRoute: true,
      clearDistance: true,
      clearDuration: true,
      clearError: true,
    );
  }

  void setDestination(LatLng coordinates, {String? label}) {
    state = state.copyWith(
      destination: coordinates,
      destinationLabel: label,
      suggestions: const [],
      clearError: true,
    );

    if (state.source == null) {
      state = state.copyWith(
        useCurrentLocationAsSource: true,
      );
    }
  }

  void setDestinationWithSource({
    required LatLng source,
    required LatLng destination,
    String? destinationLabel,
  }) {
    state = state.copyWith(
      source: source,
      sourceLabel: 'Current location',
      destination: destination,
      destinationLabel: destinationLabel,
      suggestions: const [],
      useCurrentLocationAsSource: true,
      clearError: true,
    );
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: const [], isSearching: false);
  }

  void startNavigation() {
    if (state.routePoints.isEmpty) return;
    state = state.copyWith(isNavigating: true, navigationStepIndex: 0);
  }

  void stopNavigation() {
    state = state.copyWith(isNavigating: false, navigationStepIndex: 0);
  }

  void nextNavigationStep() {
    if (state.navigationStepIndex < state.routePoints.length - 1) {
      state = state.copyWith(navigationStepIndex: state.navigationStepIndex + 1);
    }
  }

  void previousNavigationStep() {
    if (state.navigationStepIndex > 0) {
      state = state.copyWith(navigationStepIndex: state.navigationStepIndex - 1);
    }
  }

  LatLng? get currentNavigationPoint {
    if (!state.isNavigating || state.routePoints.isEmpty) return null;
    final index = state.navigationStepIndex.clamp(0, state.routePoints.length - 1);
    return state.routePoints[index];
  }

  LatLng? get nextNavigationPoint {
    if (!state.isNavigating || state.routePoints.isEmpty) return null;
    final nextIndex = (state.navigationStepIndex + 1).clamp(0, state.routePoints.length - 1);
    if (nextIndex == state.navigationStepIndex) return null;
    return state.routePoints[nextIndex];
  }
}
