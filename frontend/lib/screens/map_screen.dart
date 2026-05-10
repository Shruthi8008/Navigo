import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../features/map/application/community_controller.dart';
import '../features/map/application/location_controller.dart';
import '../features/map/application/route_controller.dart';
import '../features/map/data/map_search_service.dart';
import '../features/map/domain/place_suggestion.dart';
import '../features/map/domain/route_preference.dart';
import '../features/map/domain/route_state.dart';
import '../features/map/presentation/widgets/dialogs/comment_dialog.dart';
import '../features/map/presentation/widgets/location_status_card.dart';
import '../features/map/presentation/widgets/map_bottom_sheet.dart';
import '../features/map/presentation/widgets/map_controls.dart';
import '../features/map/presentation/widgets/route_search_panel.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _fallbackCenter = LatLng(12.9716, 77.5946);
  static const double _defaultZoom = 15;
  static const double _streetZoom = 17.5;

  final MapController _mapController = MapController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  ProviderSubscription? _locationSubscription;
  ProviderSubscription? _routeSubscription;
  ProviderSubscription? _communitySubscription;
  Timer? _searchDebounce;
  double _currentZoom = _defaultZoom;
  bool _isLoadingPlace = false;
  PlaceSuggestion? _tappedPlace;

  @override
  void initState() {
    super.initState();
    _locationSubscription = ref.listenManual(locationControllerProvider, (
      previous,
      next,
    ) {
      final previousLocation = previous?.currentLocation;
      final nextLocation = next.currentLocation;

      if (nextLocation == null) {
        return;
      }

      final routeState = ref.read(routeControllerProvider);
      if (routeState.source == null) {
        ref
            .read(routeControllerProvider.notifier)
            .useCurrentLocationAsSource(nextLocation);
      }

      if (previousLocation == null) {
        _mapController.move(nextLocation, _currentZoom);
      }
    });

    _routeSubscription = ref.listenManual(routeControllerProvider, (
      previous,
      next,
    ) {
      _syncControllerText(_sourceController, next.sourceLabel);
      _syncControllerText(_destinationController, next.destinationLabel);

      final hadRoute = previous?.hasRoute ?? false;
      if (next.hasRoute &&
          (!hadRoute || previous?.routePoints != next.routePoints)) {
        _fitRoute(next.routePoints);
      }
    });

    _communitySubscription = ref.listenManual(communityControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.selectedPlace != next.selectedPlace) {
        _tappedPlace = next.selectedPlace;
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _locationSubscription?.close();
    _routeSubscription?.close();
    _communitySubscription?.close();
    _sourceController.dispose();
    _destinationController.dispose();
    _sourceFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    if (value.isEmpty) {
      return;
    }

    if (controller == _sourceController && _sourceFocusNode.hasFocus) {
      return;
    }

    if (controller == _destinationController && _destinationFocusNode.hasFocus) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _fitRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) {
      return;
    }

    final bounds = LatLngBounds.fromPoints(routePoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 180, 48, 120),
      ),
    );
    setState(() => _currentZoom = _mapController.camera.zoom);
  }

  void _zoomIn() {
    final nextZoom = (_currentZoom + 1).clamp(3, 18).toDouble();
    _mapController.move(_mapController.camera.center, nextZoom);
    setState(() => _currentZoom = nextZoom);
  }

  void _zoomOut() {
    final nextZoom = (_currentZoom - 1).clamp(3, 18).toDouble();
    _mapController.move(_mapController.camera.center, nextZoom);
    setState(() => _currentZoom = nextZoom);
  }

  Future<void> _moveToCurrentLocation() async {
    final controller = ref.read(locationControllerProvider.notifier);
    final location = ref.read(locationControllerProvider).currentLocation;

    if (location != null) {
      _mapController.move(location, _streetZoom);
      setState(() => _currentZoom = _streetZoom);
      return;
    }

    await controller.initialize();

    final updatedLocation = ref
        .read(locationControllerProvider)
        .currentLocation;
    if (updatedLocation != null) {
      _mapController.move(updatedLocation, _streetZoom);
      setState(() => _currentZoom = _streetZoom);
    }
  }

  LatLng? _tappedLocation;

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    _sourceFocusNode.unfocus();
    _destinationFocusNode.unfocus();

    setState(() {
      _tappedLocation = point;
    });

    await ref
        .read(communityControllerProvider.notifier)
        .loadPlaceContext(
          place: null,
          routePoints: const [],
          tappedCoordinates: point,
        );

    ref.read(routeControllerProvider.notifier).clearField(RouteField.source);
    ref.read(routeControllerProvider.notifier).clearField(RouteField.destination);
  }

  void _onFieldTap(RouteField field) {
    ref.read(routeControllerProvider.notifier).setActiveField(field);
  }

  void _onFieldChanged(RouteField field, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(routeControllerProvider.notifier)
          .searchPlaces(field: field, query: value);
    });
  }

  Future<void> _onSuggestionSelected(
    RouteField field,
    PlaceSuggestion suggestion,
  ) async {
    final location = ref.read(locationControllerProvider).currentLocation;

    await ref
        .read(routeControllerProvider.notifier)
        .selectSuggestion(
          field: field,
          suggestion: suggestion,
          currentLocation: location,
        );

    if (field == RouteField.destination) {
      await ref
          .read(communityControllerProvider.notifier)
          .loadPlaceContext(
            place: suggestion,
            routePoints: const [],
          );
    }
    _sourceFocusNode.unfocus();
    _destinationFocusNode.unfocus();
  }

  Future<void> _buildRouteWithPreference() async {
    final communityState = ref.read(communityControllerProvider);
    final routeState = ref.read(routeControllerProvider);

    if (communityState.tappedCoordinates != null && routeState.destination == null) {
      final currentLocation = ref.read(locationControllerProvider).currentLocation;
      if (currentLocation != null) {
        ref.read(routeControllerProvider.notifier).setDestinationWithSource(
          source: currentLocation,
          destination: communityState.tappedCoordinates!,
        );
      } else {
        ref.read(routeControllerProvider.notifier).setDestination(
          communityState.tappedCoordinates!,
          label: 'Tap Location',
        );
      }
    }

    final selectedPreference = await _showRoutePreferenceSheet();
    if (selectedPreference == null) {
      return;
    }

    await ref.read(routeControllerProvider.notifier).buildRoute(
          routePreference: selectedPreference,
        );

    final updatedRoute = ref.read(routeControllerProvider);
    if (updatedRoute.hasRoute) {
      await ref.read(communityControllerProvider.notifier).loadPlaceContext(
            place: null,
            routePoints: updatedRoute.routePoints,
          );
    }
  }

  Future<void> _useCurrentLocationAsSource() async {
    final currentLocation = ref
        .read(locationControllerProvider)
        .currentLocation;
    final hasDestination =
        ref.read(routeControllerProvider).destination != null;

    await ref
        .read(routeControllerProvider.notifier)
        .useCurrentLocationAsSource(
          currentLocation,
          rebuildRoute: hasDestination,
        );
    _sourceFocusNode.unfocus();
  }

  Future<RoutePreference?> _showRoutePreferenceSheet() {
    return showModalBottomSheet<RoutePreference>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose route type',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.route_rounded),
                  title: const Text('Shortest Route'),
                  subtitle: const Text('Faster by distance and time'),
                  onTap: () => Navigator.pop(context, RoutePreference.shortest),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Safest Route'),
                  subtitle: const Text(
                    'Prefers roads with better community safety scores',
                  ),
                  onTap: () => Navigator.pop(context, RoutePreference.safest),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptLoginIfNeeded() async {
    if (ref.read(authProvider).valueOrNull != null) {
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(initialMode: AuthMode.login),
      ),
    );
  }

  Widget _buildLocationMarker(LatLng location) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent.withValues(alpha: 0.18),
      ),
      child: const Center(
        child: Icon(
          Icons.my_location_rounded,
          color: Colors.blueAccent,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPointMarker({required IconData icon, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: Center(child: Icon(icon, color: color, size: 26)),
    );
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) {
      return '--';
    }

    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }

    return '${distanceMeters.round()} m';
  }

  String _formatDuration(double? durationSeconds) {
    if (durationSeconds == null) {
      return '--';
    }

    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationControllerProvider);
    final routeState = ref.watch(routeControllerProvider);
    final communityState = ref.watch(communityControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: locationState.currentLocation ?? _fallbackCenter,
              initialZoom: _defaultZoom,
              onTap: _onMapTap,
              onPositionChanged: (position, hasGesture) {
                final zoom = position.zoom;
                if (zoom != _currentZoom) {
                  setState(() => _currentZoom = zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.secmap',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
              if (routeState.hasRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeState.routePoints,
                      strokeWidth: 5,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (locationState.currentLocation != null)
                    Marker(
                      point: locationState.currentLocation!,
                      width: 64,
                      height: 64,
                      child: _buildLocationMarker(
                        locationState.currentLocation!,
                      ),
                    ),
                  if (_tappedLocation != null)
                    Marker(
                      point: _tappedLocation!,
                      width: 56,
                      height: 56,
                      child: _buildPointMarker(
                        icon: Icons.place_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  if (routeState.source != null &&
                      !routeState.useCurrentLocationAsSource)
                    Marker(
                      point: routeState.source!,
                      width: 56,
                      height: 56,
                      child: _buildPointMarker(
                        icon: Icons.radio_button_checked_rounded,
                        color: Colors.teal,
                      ),
                    ),
                  if (routeState.destination != null)
                    Marker(
                      point: routeState.destination!,
                      width: 56,
                      height: 56,
                      child: _buildPointMarker(
                        icon: Icons.flag_rounded,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ],
          ),
          RouteSearchPanel(
            sourceController: _sourceController,
            destinationController: _destinationController,
            sourceFocusNode: _sourceFocusNode,
            destinationFocusNode: _destinationFocusNode,
            routeState: routeState,
            onFieldTap: _onFieldTap,
            onFieldChanged: _onFieldChanged,
            onSuggestionSelected: _onSuggestionSelected,
            onUseCurrentLocation: _useCurrentLocationAsSource,
            onClearDestination: () {
              ref
                  .read(routeControllerProvider.notifier)
                  .clearField(RouteField.destination);
            },
          ),
          MapControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onRecenter: _moveToCurrentLocation,
          ),
          if (locationState.isLoading || routeState.isRouting)
            const Positioned(
              top: 188,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(),
            ),
          if (locationState.errorMessage != null)
            LocationStatusCard(
              title: 'Location access',
              message: locationState.errorMessage!,
              primaryActionLabel: locationState.permissionDeniedForever
                  ? 'Open Settings'
                  : locationState.locationServiceDisabled
                  ? 'Enable Location'
                  : 'Try Again',
              onPrimaryAction: locationState.permissionDeniedForever
                  ? ref
                        .read(locationControllerProvider.notifier)
                        .openAppSettings
                  : locationState.locationServiceDisabled
                  ? ref
                        .read(locationControllerProvider.notifier)
                        .openLocationSettings
                  : () => ref
                        .read(locationControllerProvider.notifier)
                        .initialize(),
            )
          else if (routeState.errorMessage != null)
            LocationStatusCard(
              title: 'Route planner',
              message: routeState.errorMessage!,
              primaryActionLabel: routeState.destination != null
                  ? 'Retry Route'
                  : null,
              onPrimaryAction: routeState.destination != null
                  ? () =>
                        ref.read(routeControllerProvider.notifier).buildRoute()
                  : null,
            )
          else if (communityState.errorMessage != null)
            LocationStatusCard(
              title: 'Community',
              message: communityState.errorMessage!,
            )
          else if (communityState.selectedPlace != null || communityState.tappedCoordinates != null)
            MapBottomSheet(
              place: communityState.selectedPlace,
              routePreference: routeState.routePreference,
              placeSafetySummary: communityState.placeSafetySummary,
              roadSafetySummary: routeState.hasRoute ? communityState.roadSafetySummary : null,
              comments: communityState.comments,
              isFavorite: communityState.isFavorite,
              isSubmitting: communityState.isSubmitting,
              onFavoriteTap: () async {
                await _promptLoginIfNeeded();
                await ref
                    .read(communityControllerProvider.notifier)
                    .toggleFavorite();
              },
              onRatePlaceTap: () async {
                await _promptLoginIfNeeded();
                await RatingDialog.show(
                  context: context,
                  title: communityState.hasUserRating
                      ? 'Update your rating'
                      : 'Rate this place',
                  initialRating: communityState.userPlaceRating?['rating'] as String?,
                  onSubmit: (rating, comment) async {
                    await ref
                        .read(communityControllerProvider.notifier)
                        .addPlaceRating(rating: rating, comment: comment);
                  },
                );
              },
              onRateAreaTap: routeState.hasRoute
                  ? () async {
                      await _promptLoginIfNeeded();
                      await RatingDialog.show(
                        context: context,
                        title: 'Rate this route area',
                        onSubmit: (rating, comment) async {
                          await ref
                              .read(communityControllerProvider.notifier)
                              .addRoadRating(
                                rating: rating,
                                routePoints: routeState.routePoints,
                                comment: comment,
                              );
                        },
                      );
                    }
                  : null,
              tappedCoordinates: communityState.tappedCoordinates,
              tappedLocationComments: communityState.tappedLocationComments,
              onCommentTap: () async {
                await _promptLoginIfNeeded();
                if (!context.mounted) {
                  return;
                }
                var targetType = 'place';
                var targetKey = ref
                    .read(communityControllerProvider.notifier)
                    .placeCommentKey();
                if (routeState.routePoints.length >= 2) {
                  final selectedTarget = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: const Text('Comment on Place'),
                                onTap: () => Navigator.pop(context, 'place'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.alt_route_rounded),
                                title: const Text('Comment on Route Area'),
                                onTap: () => Navigator.pop(context, 'route'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selectedTarget == null) {
                    return;
                  }
                  targetType = selectedTarget;
                  if (targetType == 'route') {
                    targetKey = ref
                        .read(communityControllerProvider.notifier)
                        .routeCommentKey(routeState.routePoints);
                  }
                }
                await CommentDialog.show(
                  context: context,
                  title: 'Share a safety comment',
                  onSubmit: (comment) async {
                    await ref
                        .read(communityControllerProvider.notifier)
                        .addComment(
                          targetType: targetType,
                          targetKey: targetKey,
                          comment: comment,
                        );
                  },
                );
              },
              onDirectionsTap: (routeState.destination != null || communityState.tappedCoordinates != null)
                  ? _buildRouteWithPreference
                  : null,
              onClose: () {
                ref.read(communityControllerProvider.notifier).clearPlace();
                setState(() => _tappedLocation = null);
              },
            ),
        ],
      ),
    );
  }
}
