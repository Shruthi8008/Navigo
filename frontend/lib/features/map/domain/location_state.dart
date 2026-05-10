import 'package:latlong2/latlong.dart';

class LocationState {
  const LocationState({
    this.currentLocation,
    this.isLoading = false,
    this.errorMessage,
    this.permissionDeniedForever = false,
    this.locationServiceDisabled = false,
  });

  final LatLng? currentLocation;
  final bool isLoading;
  final String? errorMessage;
  final bool permissionDeniedForever;
  final bool locationServiceDisabled;

  bool get hasLocation => currentLocation != null;

  LocationState copyWith({
    LatLng? currentLocation,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? permissionDeniedForever,
    bool? locationServiceDisabled,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      permissionDeniedForever:
          permissionDeniedForever ?? this.permissionDeniedForever,
      locationServiceDisabled:
          locationServiceDisabled ?? this.locationServiceDisabled,
    );
  }
}
