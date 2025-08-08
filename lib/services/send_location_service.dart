import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationSender {
  final String buggyId;
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<Position>? _positionStream;

  LocationSender(this.buggyId);

  Future<void> start() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied.");
        return;
      }
    }

    // Cancel previous stream if any
    await _positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      try {
        await _supabase.from('buggy_locations').upsert({
          'buggy_id': buggyId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print("Location send error: $e");
      }
    });
  }

  Future<void> stop() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }
}
