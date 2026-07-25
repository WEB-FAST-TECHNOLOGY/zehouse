import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized Mapbox service for the entire application.
/// Manages the access token, map styles, default camera settings,
/// route calculation, and geolocation helpers.
class MapboxService {
  // ─── Access Token ──────────────────────────────────────────────────────────
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1Ijoid2Z0ZWNoIiwiYSI6ImNtbTIzYWZoZTAya2IycnNkcWt6d2VqeDgifQ.syIC6Kua6R-Mi8E7eUp2YQ',
  );

  // ─── Map Styles ────────────────────────────────────────────────────────────
  /// Mapbox Streets — clean urban/city style (default for main map)
  static const String styleStreets = 'mapbox://styles/mapbox/streets-v12';

  /// Default map style URL for the /map-screen — Mapbox Streets v12
  /// (carte routière avec rues, routes et points d'intérêt)
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  /// Mapbox Dark — modern high-contrast dark theme style
  static const String styleDark = 'mapbox://styles/mapbox/dark-v11';

  /// Mapbox Standard — modern 3-D style (used for mini maps)
  static const String styleStandard = 'mapbox://styles/mapbox/standard';

  /// Mapbox Satellite Streets — satellite with road overlay
  static const String styleSatelliteStreets =
      'mapbox://styles/mapbox/satellite-streets-v12';

  // ─── Active User Location ──────────────────────────────────────────────────
  static double? userLat;
  static double? userLng;

  // ─── Default Camera (Paris) ────────────────────────────────────────────────
  static const double defaultLat = 48.8566;
  static const double defaultLng = 2.3522;
  static const double defaultZoom = 11.8;
  static const double miniMapZoom = 14.0;

  // ─── Directions API ────────────────────────────────────────────────────────
  /// Base URL for the Mapbox Directions REST API.
  static const String _directionsBaseUrl =
      'https://api.mapbox.com/directions/v5/mapbox';

  /// Build a Mapbox Directions API URL for driving.
  static String buildDirectionsUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = 'driving',
  }) {
    return '$_directionsBaseUrl/$profile/'
        '$originLng,$originLat;$destLng,$destLat'
        '?access_token=$accessToken'
        '&geometries=geojson'
        '&overview=full'
        '&steps=true';
  }

  // ─── Navigation / Deep-link ────────────────────────────────────────────────
  /// Open the device's native navigation app (Google Maps, Apple Maps, Waze…)
  /// to a destination by coordinates or address.
  /// - Web: opens Google Maps in a new tab
  /// - Android: opens Google Maps (or any navigation app via geo: URI)
  /// - iOS: opens Apple Maps (or any navigation app via maps: URI)
  static Future<void> openDirections({
    double? destLat,
    double? destLng,
    String? address,
  }) async {
    if (destLat == null && destLng == null && address == null) return;

    Uri? uri;

    if (kIsWeb) {
      // Web: open Google Maps in a new browser tab
      if (destLat != null && destLng != null) {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
        );
      } else if (address != null) {
        final encoded = Uri.encodeComponent(address);
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving',
        );
      }
    } else {
      // Determine destination string
      final String dest = (destLat != null && destLng != null)
          ? '$destLat,$destLng'
          : Uri.encodeComponent(address ?? '');

      final String destLabel = (address != null)
          ? Uri.encodeComponent(address)
          : dest;

      // Try Google Maps first (works on Android and iOS if installed)
      final googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
      );

      // iOS Apple Maps URI
      final appleMapsUri = Uri.parse(
        'https://maps.apple.com/?daddr=$dest&dirflg=d',
      );

      // geo: URI — opens any navigation app on Android
      final geoUri = (destLat != null && destLng != null)
          ? Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng($destLabel)')
          : Uri.parse('geo:0,0?q=$dest');

      // On Android prefer geo: URI so the user can choose their navigation app
      // On iOS prefer Apple Maps URI
      try {
        if (await canLaunchUrl(geoUri)) {
          await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      try {
        if (await canLaunchUrl(appleMapsUri)) {
          await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      // Final fallback: Google Maps web URL
      uri = googleMapsUri;
    }

    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Convenience: open directions by address string only.
  static Future<void> openDirectionsByAddress(String address) async {
    await openDirections(address: address);
  }

  // ─── Geocoding ─────────────────────────────────────────────────────────────
  /// Build a Mapbox Geocoding API URL for a forward geocode query.
  static String buildGeocodingUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
        '?access_token=$accessToken'
        '&limit=5'
        '&language=fr';
  }

  // ─── Static Map Image ──────────────────────────────────────────────────────
  /// Build a Mapbox Static Images API URL for a given location.
  static String buildStaticMapUrl({
    required double lat,
    required double lng,
    int width = 600,
    int height = 300,
    double zoom = 14.0,
    String style = 'streets-v12',
  }) {
    return 'https://api.mapbox.com/styles/v1/mapbox/$style/static/'
        'pin-s+E85D4A($lng,$lat)/'
        '$lng,$lat,$zoom,0/${width}x$height'
        '?access_token=$accessToken';
  }
}
