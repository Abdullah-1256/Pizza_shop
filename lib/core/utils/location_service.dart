import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      // Use location settings for better accuracy
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get formatted address suitable for delivery
  Future<String> getDeliveryAddress() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return await getFormattedDeliveryAddress(
        position.latitude,
        position.longitude,
      );
    }
    return 'Please enable location services for accurate delivery address';
  }

  /// Get current city from GPS
  Future<String?> getCurrentCity() async {
    final position = await getCurrentPosition();
    if (position != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          return place.locality ??
              place.subLocality ??
              place.administrativeArea;
        }
      } catch (e) {
        print('Error getting city: $e');
      }
    }
    return null;
  }

  /// Get full address details for saving
  Future<Map<String, String>?> getFullAddressDetails() async {
    final position = await getCurrentPosition();
    if (position != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];

          // Build address components
          final street = place.street ?? '';
          final city = place.locality ?? place.subLocality ?? '';
          final state = place.administrativeArea ?? '';
          final postalCode = place.postalCode ?? '';
          final country = place.country ?? '';

          return {
            'street': street,
            'city': city,
            'state': state,
            'postal_code': postalCode,
            'country': country,
            'full_address':
                '$street, $city${state.isNotEmpty ? ', $state' : ''}${postalCode.isNotEmpty ? ' $postalCode' : ''}${country.isNotEmpty ? ', $country' : ''}',
          };
        }
      } catch (e) {
        print('Error getting address details: $e');
      }
    }
    return null;
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build a complete address string for delivery
        List<String> addressParts = [];

        // Add street number and name
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }

        // Add postal code if available
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        // Add locality (city/town)
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        // Add administrative area (state/province)
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        // Add country
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }

        // Fallback to basic format
        return '${place.locality}, ${place.country}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Location not available';
    }
  }

  Future<String> getCurrentAddress() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
    }
    return 'Location not available';
  }

  /// Get a nicely formatted delivery address
  Future<String> getFormattedDeliveryAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Create a delivery-friendly address format
        String street = '';
        if (place.street != null && place.street!.isNotEmpty) {
          street = place.street!;
        }

        String city = '';
        if (place.locality != null && place.locality!.isNotEmpty) {
          city = place.locality!;
        } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          city = place.subLocality!;
        }

        String state = '';
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          state = place.administrativeArea!;
        }

        String postalCode = '';
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          postalCode = place.postalCode!;
        }

        // Build the delivery address
        List<String> addressParts = [];

        if (street.isNotEmpty) {
          addressParts.add(street);
        }
        if (city.isNotEmpty) {
          addressParts.add(city);
        }
        if (state.isNotEmpty && state != city) {
          addressParts.add(state);
        }
        if (postalCode.isNotEmpty) {
          addressParts.add(postalCode);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }

        // Fallback to basic format
        return '${place.locality ?? 'Unknown City'}, ${place.country ?? 'Unknown Country'}';
      }
      return 'Address not found';
    } catch (e) {
      print('Error getting formatted address: $e');
      return 'Unable to get address';
    }
  }
}
