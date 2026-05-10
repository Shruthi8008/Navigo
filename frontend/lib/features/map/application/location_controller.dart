import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/location_state.dart';

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

class LocationController extends Notifier<LocationState> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  LocationState build() {
    ref.onDispose(() => _positionSubscription?.cancel());
    Future<void>.microtask(initialize);
    return const LocationState(isLoading: true);
  }

  Future<void> initialize() async {
    if (state.isLoading && state.hasLocation) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      permissionDeniedForever: false,
      locationServiceDisabled: false,
    );

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _updateLocation(position);
      await _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            _updateLocation,
            onError: (Object error) {
              state = state.copyWith(
                isLoading: false,
                errorMessage: 'Unable to track live location updates.',
              );
            },
          );
    } on LocationServiceDisabledException {
      state = state.copyWith(
        isLoading: false,
        locationServiceDisabled: true,
        errorMessage: 'Turn on location services to use live tracking.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to fetch your current location.',
      );
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        locationServiceDisabled: true,
        errorMessage: 'Location services are turned off.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(
        errorMessage: 'Location permission is required to show your position.',
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        permissionDeniedForever: true,
        errorMessage:
            'Location permission is permanently denied. Enable it in app settings.',
      );
      return false;
    }

    return true;
  }

  void _updateLocation(Position position) {
    state = state.copyWith(
      currentLocation: LatLng(position.latitude, position.longitude),
      isLoading: false,
      clearError: true,
      permissionDeniedForever: false,
      locationServiceDisabled: false,
    );
  }
}
