import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.coordinates,
  });

  final String name;
  final String address;
  final LatLng coordinates;
}
