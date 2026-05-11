import 'package:latlong2/latlong.dart';

class LocationState {
  const LocationState({
    this.currentLocation,
    this.isLoading = false,
    this.errorMessage,
    this.permissionDeniedForever = false,
    this.locationServiceDisabled = false,
    this.isNavigating = false,
  });

  final LatLng? currentLocation;
  final bool isLoading;
  final String? errorMessage;
  final bool permissionDeniedForever;
  final bool locationServiceDisabled;
  final bool isNavigating;

  bool get hasLocation => currentLocation != null;

  LocationState copyWith({
    LatLng? currentLocation,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? permissionDeniedForever,
    bool? locationServiceDisabled,
    bool? isNavigating,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      permissionDeniedForever:
          permissionDeniedForever ?? this.permissionDeniedForever,
      locationServiceDisabled:
          locationServiceDisabled ?? this.locationServiceDisabled,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}
