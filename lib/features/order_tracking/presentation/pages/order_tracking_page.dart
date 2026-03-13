import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/delivery_location_service.dart';
import '../../../../core/utils/location_service.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with TickerProviderStateMixin {
  MapController? _mapController;
  List<latlong.LatLng> _locationHistory = [];
  StreamSubscription<List<Map<String, dynamic>>>? _locationSubscription;
  bool _mapError = false;
  dynamic _orderUpdatesSubscription;

  // Delivery person data
  String? _deliveryPersonId;
  String? _deliveryPersonName;
  String? _deliveryPersonPhone;
  latlong.LatLng _deliveryPersonLocation = const latlong.LatLng(
    24.8607,
    67.0011,
  );
  latlong.LatLng _customerLocation = const latlong.LatLng(
    24.8607,
    67.0011,
  ); // Will be updated with current location

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _currentStatus = 'Order Confirmed';
  String _estimatedTime = '25-30 mins';
  double _progressValue = 0.2;

  final List<Map<String, dynamic>> _statusSteps = [
    {
      'status': 'Order Confirmed',
      'icon': Icons.check_circle,
      'completed': true,
    },
    {'status': 'Preparing Food', 'icon': Icons.restaurant, 'completed': false},
    {
      'status': 'Out for Delivery',
      'icon': Icons.delivery_dining,
      'completed': false,
    },
    {'status': 'Delivered', 'icon': Icons.home, 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupAnimations();
    _loadOrderDetails();
    _loadDeliveryAssignment();
    _subscribeToLocationUpdates();
    _subscribeToOrderUpdates();
    _loadLocationHistory();
  }

  void _initializeMap() async {
    try {
      // Always try to get current location first
      final locationService = LocationService();
      final currentPosition = await locationService.getCurrentPosition();

      if (currentPosition != null) {
        // Use current GPS location
        _customerLocation = latlong.LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        print(
          '✅ Using current GPS location: ${_customerLocation.latitude}, ${_customerLocation.longitude}',
        );
      } else {
        // If GPS fails, try to get location from order data (latitude/longitude from database)
        final orderLat = widget.orderData['latitude'];
        final orderLng = widget.orderData['longitude'];

        if (orderLat != null && orderLng != null) {
          _customerLocation = latlong.LatLng(
            orderLat.toDouble(),
            orderLng.toDouble(),
          );
          print('📍 Using order location from database: $orderLat, $orderLng');
        } else {
          // Last resort: use a default location (but show warning)
          _customerLocation = const latlong.LatLng(24.8607, 67.0011);
          print(
            '⚠️ Using default location - GPS and order location unavailable',
          );
        }
      }

      // Initialize location history with current positions
      _locationHistory = [_customerLocation, _deliveryPersonLocation];
    } catch (e) {
      print('❌ Error initializing map: $e');
      // Even on error, try to use order location if available
      final orderLat = widget.orderData['latitude'];
      final orderLng = widget.orderData['longitude'];

      if (orderLat != null && orderLng != null) {
        _customerLocation = latlong.LatLng(
          orderLat.toDouble(),
          orderLng.toDouble(),
        );
        _locationHistory = [_customerLocation, _deliveryPersonLocation];
      } else {
        setState(() {
          _mapError = true;
        });
      }
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadOrderDetails() async {
    try {
      final orderResponse = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', widget.orderId)
          .single();

      if (mounted && orderResponse != null) {
        final backendStatus = orderResponse['status'] as String?;
        if (backendStatus != null) {
          final formattedStatus = _formatStatus(backendStatus);
          setState(() {
            _currentStatus = formattedStatus;
            _updateStatusSteps(formattedStatus);
          });
          print('Initial order status loaded from backend: $_currentStatus');
        }
      }
    } catch (e) {
      print('Error loading order details: $e');
    }
  }

  void _simulateDeliveryProgress() {
    // Simulate delivery progress updates
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'Preparing Food';
          _progressValue = 0.4;
          _statusSteps[1]['completed'] = true;
        });
      }
    });

    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'Out for Delivery';
          _progressValue = 0.7;
          _statusSteps[2]['completed'] = true;
          _estimatedTime = '10-15 mins';
        });
      }
    });

    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'Delivered';
          _progressValue = 1.0;
          _statusSteps[3]['completed'] = true;
          _estimatedTime = 'Delivered';
        });
      }
    });
  }

  Future<void> _loadDeliveryAssignment() async {
    try {
      final assignmentResponse = await Supabase.instance.client
          .from('delivery_assignments')
          .select('*, delivery_personnel(*)')
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (mounted && assignmentResponse != null) {
        setState(() {
          _deliveryPersonId = assignmentResponse['delivery_person_id'];
          _deliveryPersonName =
              assignmentResponse['delivery_personnel']['name'];
          _deliveryPersonPhone =
              assignmentResponse['delivery_personnel']['phone'];

          // Only update status from delivery assignment if we don't have a status from orders table yet
          // The orders table status takes priority as it's the master status
          final assignmentStatus = assignmentResponse['status'];
          if (assignmentStatus != null && _currentStatus == 'Order Confirmed') {
            final formattedStatus = _formatStatus(assignmentStatus);
            _currentStatus = formattedStatus;
            _updateStatusSteps(formattedStatus);
          }
        });

        // Load current location of delivery person
        if (_deliveryPersonId != null) {
          final locationData = await DeliveryLocationService()
              .getDeliveryPersonLocation(_deliveryPersonId!);
          if (locationData != null &&
              locationData['current_location'] != null) {
            final location = locationData['current_location'];
            setState(() {
              _deliveryPersonLocation = latlong.LatLng(
                location['lat'],
                location['lng'],
              );
            });
            _updateMapView();
          }
        }
      } else {
        // No delivery assignment yet - this is normal for new orders
        print(
          'No delivery assignment found for order ${widget.orderId} - this is normal for new orders',
        );
      }
    } catch (e) {
      print('Error loading delivery assignment: $e');
    }
  }

  void _subscribeToLocationUpdates() {
    // Use channel-based subscription for delivery locations of this order
    RealtimeService.createDeliveryLocationSubscription(widget.orderId, (
      payload,
    ) {
      if (mounted) {
        final newRecord = payload.newRecord;
        if (newRecord != null) {
          final location = newRecord['location'];
          if (location != null) {
            setState(() {
              _deliveryPersonLocation = latlong.LatLng(
                location['lat'],
                location['lng'],
              );
              _locationHistory.add(_deliveryPersonLocation);
            });
            // Update map view to show new location
            _updateMapView();
          }
        }
      }
    }).subscribe();
  }

  void _subscribeToOrderUpdates() {
    // Use channel-based subscription for specific order
    _orderUpdatesSubscription = RealtimeService.createOrderSubscription(
      widget.orderId,
      (payload) {
        if (mounted) {
          final newRecord = payload.newRecord;
          if (newRecord != null) {
            final newStatus = newRecord['status'];
            if (newStatus != null) {
              final formattedStatus = _formatStatus(newStatus);
              print(
                '🔄 Real-time order status update: $newStatus -> $formattedStatus',
              );

              setState(() {
                _currentStatus = formattedStatus;
                _updateStatusSteps(formattedStatus);

                // Update estimated time based on status
                if (formattedStatus == 'Out for Delivery') {
                  _estimatedTime = '10-15 mins';
                } else if (formattedStatus == 'Delivered') {
                  _estimatedTime = 'Delivered';
                }
              });

              // Show notification for status changes
              _showStatusUpdateNotification(formattedStatus);
            }
          }
        }
      },
    ).subscribe();
  }

  Future<void> _loadLocationHistory() async {
    try {
      final history = await DeliveryLocationService().getLocationHistory(
        widget.orderId,
      );
      if (mounted && history.isNotEmpty) {
        setState(() {
          _locationHistory = history.map((item) {
            final loc = item['location'];
            return latlong.LatLng(loc['lat'], loc['lng']);
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading location history: $e');
    }
  }

  void _updateMapView() {
    // Update the location history to include current delivery person location
    if (_locationHistory.isNotEmpty) {
      setState(() {
        _locationHistory = [_customerLocation, _deliveryPersonLocation];
      });
    }
  }

  Future<bool> _checkMapAvailability() async {
    // Simple check - in a real app, you might check if Google Maps is loaded
    // For now, we'll assume it's available unless we know it's not
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Small delay to let map initialize
    return !_mapError;
  }

  String _formatStatus(String status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Order Confirmed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'assigned':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Food';
      case 'ready':
        return 'Preparing Food';
      case 'picked_up':
        return 'Out for Delivery';
      case 'en_route':
        return 'Out for Delivery';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        print('Unknown status received: $status');
        return 'Order Confirmed';
    }
  }

  void _updateStatusSteps(String currentStatus) {
    setState(() {
      for (var step in _statusSteps) {
        step['completed'] = false;
      }

      if (currentStatus == 'Order Confirmed') {
        _statusSteps[0]['completed'] = true;
        _progressValue = 0.2;
      } else if (currentStatus == 'Preparing Food') {
        _statusSteps[0]['completed'] = true;
        _statusSteps[1]['completed'] = true;
        _progressValue = 0.4;
      } else if (currentStatus == 'Out for Delivery') {
        _statusSteps[0]['completed'] = true;
        _statusSteps[1]['completed'] = true;
        _statusSteps[2]['completed'] = true;
        _progressValue = 0.7;
      } else if (currentStatus == 'Delivered') {
        _statusSteps[0]['completed'] = true;
        _statusSteps[1]['completed'] = true;
        _statusSteps[2]['completed'] = true;
        _statusSteps[3]['completed'] = true;
        _progressValue = 1.0;
      }
    });
  }

  void _showStatusUpdateNotification(String status) {
    String message;
    Color backgroundColor;

    switch (status) {
      case 'Order Confirmed':
        message = 'Your order has been confirmed!';
        backgroundColor = Colors.blue;
        break;
      case 'Preparing Food':
        message = 'Your food is being prepared!';
        backgroundColor = Colors.orange;
        break;
      case 'Out for Delivery':
        message = 'Your order is out for delivery!';
        backgroundColor = Colors.green;
        break;
      case 'Delivered':
        message = 'Your order has been delivered! Enjoy your meal!';
        backgroundColor = Colors.green;
        break;
      default:
        message = 'Order status updated: $status';
        backgroundColor = Colors.blue;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    if (_orderUpdatesSubscription != null) {
      _orderUpdatesSubscription.unsubscribe();
    }
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/product'),
        ),
        title: Text(
          'Track Your Order',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Builder(
                  builder: (context) {
                    // Try to load Google Map, fallback to static map if it fails
                    return FutureBuilder<bool>(
                      future: _checkMapAvailability(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasData &&
                            snapshot.data == true &&
                            !_mapError) {
                          try {
                            return FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: _customerLocation,
                                zoom: 15.0,
                                onTap: (_, __) {
                                  // Handle map tap if needed
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _customerLocation,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                    Marker(
                                      point: _deliveryPersonLocation,
                                      child: const Icon(
                                        Icons.delivery_dining,
                                        color: Colors.green,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_locationHistory.length > 1)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _locationHistory,
                                        color: Colors.blue,
                                        strokeWidth: 4.0,
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          } catch (e) {
                            print('FlutterMap rendering error: $e');
                            return _buildMapFallbackUI();
                          }
                        } else {
                          return _buildMapFallbackUI();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Order Status Section
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${widget.orderData['order_number'] ?? widget.orderId.substring(0, 8)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _estimatedTime,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Status
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentStatus,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Your order is on the way!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Steps
                  ..._statusSteps.map((step) => _buildStatusStep(step)),
                ],
              ),
            ),
          ),

          // Delivery Person Info - Only show when order is out for delivery
          if (_currentStatus == 'Out for Delivery' &&
              _deliveryPersonName != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _deliveryPersonName!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _deliveryPersonPhone ?? 'Delivery Partner',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _deliveryPersonPhone != null
                            ? () async {
                                final Uri phoneUri = Uri(
                                  scheme: 'tel',
                                  path: _deliveryPersonPhone,
                                );
                                if (await canLaunchUrl(phoneUri)) {
                                  await launchUrl(phoneUri);
                                }
                              }
                            : null,
                        icon: Icon(
                          Icons.phone,
                          color: _deliveryPersonPhone != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      IconButton(
                        onPressed: _deliveryPersonPhone != null
                            ? () async {
                                final Uri smsUri = Uri(
                                  scheme: 'sms',
                                  path: _deliveryPersonPhone,
                                );
                                if (await canLaunchUrl(smsUri)) {
                                  await launchUrl(smsUri);
                                }
                              }
                            : null,
                        icon: Icon(
                          Icons.message,
                          color: _deliveryPersonPhone != null
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapFallbackUI() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Free OpenStreetMap',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Using Free OpenStreetMap!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This app uses OpenStreetMap which is completely free and requires no API keys or setup.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('✅ No API keys required', null),
                    _buildInstructionStep('✅ No setup needed', null),
                    _buildInstructionStep('✅ Completely free to use', null),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'If the map still doesn\'t load, check your internet connection.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _mapError = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: Text('Retry', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String text, String? link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          Expanded(
            child: link != null
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text: ' (${link})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(Map<String, dynamic> step) {
    final isCompleted = step['completed'] as bool;
    final isCurrent = step['status'] == _currentStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              step['icon'] as IconData,
              color: isCompleted ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['status'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isCurrent ? Colors.orange : Colors.black87,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'In progress...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
