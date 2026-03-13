import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  static bool _isInitialized = false;

  // Stream controllers for different data types
  static final StreamController<List<Map<String, dynamic>>> _ordersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static final StreamController<List<Map<String, dynamic>>>
  _complaintsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static final StreamController<List<Map<String, dynamic>>>
  _deliveryAssignmentsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static final StreamController<List<Map<String, dynamic>>>
  _deliveryLocationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static final StreamController<List<Map<String, dynamic>>>
  _deliveryPersonnelController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Stream subscriptions
  static StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  static StreamSubscription<List<Map<String, dynamic>>>?
  _complaintsSubscription;
  static StreamSubscription<List<Map<String, dynamic>>>?
  _deliveryAssignmentsSubscription;
  static StreamSubscription<List<Map<String, dynamic>>>?
  _deliveryLocationsSubscription;
  static StreamSubscription<List<Map<String, dynamic>>>?
  _deliveryPersonnelSubscription;

  // Public streams
  static Stream<List<Map<String, dynamic>>> get ordersStream =>
      _ordersController.stream;
  static Stream<List<Map<String, dynamic>>> get complaintsStream =>
      _complaintsController.stream;
  static Stream<List<Map<String, dynamic>>> get deliveryAssignmentsStream =>
      _deliveryAssignmentsController.stream;
  static Stream<List<Map<String, dynamic>>> get deliveryLocationsStream =>
      _deliveryLocationsController.stream;
  static Stream<List<Map<String, dynamic>>> get deliveryPersonnelStream =>
      _deliveryPersonnelController.stream;

  static Future<void> init() async {
    if (_isInitialized) return;

    print('🚀 Initializing Supabase Realtime Channels...');

    try {
      final supabase = Supabase.instance.client;

      // Orders Channel - Listen to all orders for admin
      supabase
          .channel('admin:orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              print(
                '📢 Admin Orders Event: ${payload.eventType} -> ${payload.newRecord?['id']}',
              );
              // Trigger orders refresh for admin dashboard
              if (payload.newRecord != null) {
                _ordersController.add([payload.newRecord!]);
              }
            },
          )
          .subscribe();

      // Complaints Channel - Listen to all complaints for admin
      supabase
          .channel('admin:complaints')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'complaints',
            callback: (payload) {
              print(
                '📢 Admin Complaints Event: ${payload.eventType} -> ${payload.newRecord?['id']}',
              );
              // Trigger complaints refresh for admin dashboard
              if (payload.newRecord != null) {
                _complaintsController.add([payload.newRecord!]);
              }
            },
          )
          .subscribe();

      // Delivery Assignments Channel
      supabase
          .channel('delivery:assignments')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'delivery_assignments',
            callback: (payload) {
              print('📢 Delivery Assignment Event: ${payload.eventType}');
              if (payload.newRecord != null) {
                _deliveryAssignmentsController.add([payload.newRecord!]);
              }
            },
          )
          .subscribe();

      // Delivery Locations Channel
      supabase
          .channel('delivery:locations')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'delivery_locations',
            callback: (payload) {
              print('📍 Delivery Location Event: ${payload.eventType}');
              if (payload.newRecord != null) {
                _deliveryLocationsController.add([payload.newRecord!]);
              }
            },
          )
          .subscribe();

      // Delivery Personnel Channel
      supabase
          .channel('delivery:personnel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'delivery_personnel',
            callback: (payload) {
              print('👥 Delivery Personnel Event: ${payload.eventType}');
              if (payload.newRecord != null) {
                _deliveryPersonnelController.add([payload.newRecord!]);
              }
            },
          )
          .subscribe();

      _isInitialized = true;
      print('✅ Supabase Realtime Channels initialized successfully!');
    } catch (e) {
      print('❌ Error initializing realtime channels: $e');
      rethrow;
    }
  }

  // Helper method to create order-specific subscription
  static RealtimeChannel createOrderSubscription(
    String orderId,
    Function(PostgresChangePayload) callback,
  ) {
    return Supabase.instance.client
        .channel('order:$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: callback,
        );
  }

  // Helper method to create user-specific complaints subscription
  static RealtimeChannel createUserComplaintsSubscription(
    String userId,
    Function(PostgresChangePayload) callback,
  ) {
    return Supabase.instance.client
        .channel('user:complaints:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: callback,
        );
  }

  // Helper method to create delivery location subscription for specific order
  static RealtimeChannel createDeliveryLocationSubscription(
    String orderId,
    Function(PostgresChangePayload) callback,
  ) {
    return Supabase.instance.client
        .channel('delivery:location:$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: callback,
        );
  }

  static Future<void> disconnect() async {
    await _ordersSubscription?.cancel();
    await _complaintsSubscription?.cancel();
    await _deliveryAssignmentsSubscription?.cancel();
    await _deliveryLocationsSubscription?.cancel();
    await _deliveryPersonnelSubscription?.cancel();

    await _ordersController.close();
    await _complaintsController.close();
    await _deliveryAssignmentsController.close();
    await _deliveryLocationsController.close();
    await _deliveryPersonnelController.close();

    _isInitialized = false;
    print('🛑 Realtime streams disconnected');
  }
}
