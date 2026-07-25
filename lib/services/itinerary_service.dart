import './mapbox_service.dart';

/// Service for launching Mapbox navigation — delegates to [MapboxService].
class ItineraryService {
  /// Open Mapbox navigation to a destination by coordinates or address.
  static Future<void> openDirections({
    double? destLat,
    double? destLng,
    String? address,
  }) async {
    await MapboxService.openDirections(
      destLat: destLat,
      destLng: destLng,
      address: address,
    );
  }

  /// Open Mapbox navigation to a destination by address string only.
  static Future<void> openDirectionsByAddress(String address) async {
    await MapboxService.openDirectionsByAddress(address);
  }
}
