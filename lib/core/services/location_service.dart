import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) return false;
    if (permission == LocationPermission.deniedForever) return false;
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
    if (pos == null) return null;

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

      if (parts.isNotEmpty) return parts.join(', ');
    } catch (_) {
      // fall back to coordinates below
    }

    return 'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
  }
}

