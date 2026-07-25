import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Centralized real-time GPS location service for Zehouse.
/// Uses a broadcast stream to allow multiple parts of the app
/// (e.g., MapScreen, nearby services) to subscribe to location updates.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationStreamController = StreamController<Position>.broadcast();

  /// Stream of user location updates.
  Stream<Position> get locationStream => _locationStreamController.stream;

  /// The last known position of the user.
  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  bool _isStreaming = false;

  /// Checks permissions and starts broadcasting location updates.
  /// Should be called when the MapScreen or other location-aware feature opens.
  Future<void> startLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update every 10 meters
  }) async {
    if (_isStreaming) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          '[LocationService] Location permissions are permanently denied.',
        );
        return;
      }

      _isStreaming = true;

      // Get initial position quickly
      try {
        _lastKnownPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: accuracy),
        );
        if (_lastKnownPosition != null) {
          _locationStreamController.add(_lastKnownPosition!);
        }
      } catch (e) {
        debugPrint('[LocationService] Error getting initial position: $e');
      }

      // Start the stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      ).listen((Position position) {
        _lastKnownPosition = position;
        _locationStreamController.add(position);
      }, onError: (e) {
        debugPrint('[LocationService] Location stream error: $e');
      });
      
      debugPrint('[LocationService] Started real-time location streaming.');
    } catch (e) {
      debugPrint('[LocationService] Error starting location stream: $e');
      _isStreaming = false;
    }
  }

  /// Stops the location stream to save battery when not needed.
  void stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isStreaming = false;
    debugPrint('[LocationService] Stopped real-time location streaming.');
  }

  void dispose() {
    stopLocationStream();
    _locationStreamController.close();
  }
}
