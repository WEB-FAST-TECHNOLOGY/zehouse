import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> initMapbox(String token) async {
  MapboxOptions.setAccessToken(token);
}
