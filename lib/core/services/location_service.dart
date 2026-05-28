import 'dart:async';
import 'dart:developer' show log;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('LocationService: Location service is not enabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      log(
        'LocationService: Permission was denied, requested permission. Result: $permission',
      );
    }
    if (permission == LocationPermission.denied) {
      log('LocationService: Permission was denied');
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      log('LocationService: Permission was denied forever');
      return false;
    }
    log('LocationService: Permission granted');
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final ok = await ensurePermission();
    if (!ok) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 8),
    );
  }

  Future<String?> getCurrentAddressString() async {
    final pos = await getCurrentPosition();
    if (pos == null) {
      log('LocationService: Failed to get current position');
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.isEmpty ? null : placemarks.first;
      final parts = <String>[
        if (p?.street != null && p!.street!.trim().isNotEmpty) p.street!.trim(),
        if (p?.subLocality != null && p!.subLocality!.trim().isNotEmpty)
          p.subLocality!.trim(),
        if (p?.locality != null && p!.locality!.trim().isNotEmpty)
          p.locality!.trim(),
        if (p?.administrativeArea != null &&
            p!.administrativeArea!.trim().isNotEmpty)
          p.administrativeArea!.trim(),
      ];

      if (parts.isNotEmpty) {
        log('LocationService: Successfully got address: ${parts.join(", ")}');
        return parts.join(', ');
      }
    } catch (e, stack) {
      log('LocationService: Geocoding failed: $e');
      log('Stack trace: $stack');
    }

    final fallbackText =
        'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
    log('LocationService: Using fallback location: $fallbackText');
    return fallbackText;
  }
}
