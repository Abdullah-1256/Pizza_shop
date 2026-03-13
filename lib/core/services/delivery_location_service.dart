import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/location_service.dart';

class DeliveryLocationService {
  static final DeliveryLocationService _instance =
      DeliveryLocationService._internal();
  factory DeliveryLocationService() => _instance;
  DeliveryLocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;
  String? _currentDeliveryPersonId;
  String? _currentOrderId;
  bool _isTracking = false;

  /// Start tracking delivery person's location
  Future<void> startLocationTracking(
    String deliveryPersonId,
    String orderId,
  ) async {
    if (_isTracking) {
      await stopLocationTracking();
    }

    _currentDeliveryPersonId = deliveryPersonId;
    _currentOrderId = orderId;
    _isTracking = true;

    // Request location permission
    final hasPermission = await LocationService().requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Start continuous location updates
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
            timeLimit: Duration(seconds: 10),
          ),
        ).listen(
          (Position position) {
            _updateLocation(position);
          },
          onError: (error) {
            print('Location tracking error: $error');
          },
        );

    print(
      'Started location tracking for delivery person: $deliveryPersonId, order: $orderId',
    );
  }

  /// Stop tracking delivery person's location
  Future<void> stopLocationTracking() async {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _currentDeliveryPersonId = null;
    _currentOrderId = null;
    _isTracking = false;
    print('Stopped location tracking');
  }

  /// Update delivery person's location in database
  Future<void> _updateLocation(Position position) async {
    if (_currentDeliveryPersonId == null || _currentOrderId == null) return;

    try {
      // Update current location in delivery_personnel table
      await Supabase.instance.client
          .from('delivery_personnel')
          .update({
            'current_location': {
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            },
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentDeliveryPersonId!);

      // Insert location history
      await Supabase.instance.client.from('delivery_locations').insert({
        'delivery_person_id': _currentDeliveryPersonId,
        'order_id': _currentOrderId,
        'location': {'lat': position.latitude, 'lng': position.longitude},
        'speed': position.speed,
        'heading': position.heading,
      });

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get current location of a delivery person
  Future<Map<String, dynamic>?> getDeliveryPersonLocation(
    String deliveryPersonId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('delivery_personnel')
          .select('current_location, name')
          .eq('id', deliveryPersonId)
          .single();

      return response;
    } catch (e) {
      print('Error getting delivery person location: $e');
      return null;
    }
  }

  /// Get location history for an order
  Future<List<Map<String, dynamic>>> getLocationHistory(String orderId) async {
    try {
      final response = await Supabase.instance.client
          .from('delivery_locations')
          .select('location, timestamp, speed, heading')
          .eq('order_id', orderId)
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting location history: $e');
      return [];
    }
  }

  /// Update delivery assignment status
  Future<void> updateDeliveryStatus(String orderId, String status) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'delivered') {
        updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
      }

      await Supabase.instance.client
          .from('delivery_assignments')
          .update(updateData)
          .eq('order_id', orderId);

      // Also update order status
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);

      print('Updated delivery status to: $status for order: $orderId');
    } catch (e) {
      print('Error updating delivery status: $e');
    }
  }

  bool get isTracking => _isTracking;
  String? get currentDeliveryPersonId => _currentDeliveryPersonId;
  String? get currentOrderId => _currentOrderId;
}
