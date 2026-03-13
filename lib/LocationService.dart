import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<String> getCurrentAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ✅ Check service enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled';
    }

    // ✅ Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission permanently denied';
    }

    // ✅ Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ✅ Convert to readable address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return "${place.locality}, ${place.administrativeArea}";
    } else {
      return "Location not found";
    }
  }
}
