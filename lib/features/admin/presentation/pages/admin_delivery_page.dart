import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/delivery_location_service.dart';
import '../widgets/admin_sidebar.dart';

class AdminDeliveryPage extends StatefulWidget {
  const AdminDeliveryPage({super.key});

  @override
  State<AdminDeliveryPage> createState() => _AdminDeliveryPageState();
}

class _AdminDeliveryPageState extends State<AdminDeliveryPage> {
  List<Map<String, dynamic>> _riders = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _isLoading = true;

  // Rider registration form controllers
  final _riderFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _profileImageController = TextEditingController();
  String _selectedVehicleType = 'bike';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
  }

  Future<void> _loadDeliveryData() async {
    try {
      setState(() => _isLoading = true);

      // Load delivery personnel
      final ridersResponse = await Supabase.instance.client
          .from('delivery_personnel')
          .select('*')
          .order('name');

      // Load active deliveries with assignments
      final deliveriesResponse = await Supabase.instance.client
          .from('delivery_assignments')
          .select('*, orders(*), delivery_personnel(*)')
          .inFilter('status', ['assigned', 'picked_up', 'en_route'])
          .order('assigned_at', ascending: false);

      // Load pending orders that need assignment
      final allOrdersResponse = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('status', 'confirmed')
          .order('created_at', ascending: false);

      // Filter out orders that already have assignments
      final assignedOrderIds = deliveriesResponse
          .map((d) => d['order_id'])
          .toSet();
      final unassignedOrders = List<Map<String, dynamic>>.from(
        allOrdersResponse,
      ).where((order) => !assignedOrderIds.contains(order['id'])).toList();

      final riders = List<Map<String, dynamic>>.from(ridersResponse);
      final deliveries = List<Map<String, dynamic>>.from(deliveriesResponse);

      // Process riders data
      final processedRiders = riders.map((rider) {
        // Determine status based on assignments
        final hasActiveAssignment = deliveries.any(
          (delivery) =>
              delivery['delivery_person_id'] == rider['id'] &&
              [
                'assigned',
                'picked_up',
                'en_route',
              ].contains(delivery['status']),
        );

        return {
          'id': rider['id'],
          'name': rider['name'],
          'phone': rider['phone'] ?? '',
          'email': rider['email'] ?? '',
          'status': hasActiveAssignment
              ? 'busy'
              : (rider['is_active'] ? 'available' : 'offline'),
          'total_deliveries': 0, // Would need to calculate from history
          'rating': 4.5, // Would need to calculate from ratings
          'vehicle_type': rider['vehicle_type'] ?? 'bike',
          'current_location':
              rider['current_location']?['address'] ?? 'Unknown',
        };
      }).toList();

      // Process deliveries data
      final processedDeliveries = deliveries.map((assignment) {
        final order = assignment['orders'];
        final rider = assignment['delivery_personnel'];

        return {
          'id': assignment['id'],
          'order_id': order['id'],
          'customer_name': order['customer_name'] ?? 'Unknown',
          'customer_address': order['delivery_address'] ?? '',
          'rider_id': rider['id'],
          'rider_name': rider['name'],
          'status': assignment['status'],
          'estimated_delivery': _calculateEstimatedTime(
            assignment['estimated_delivery_time'],
          ),
          'order_total': order['total_amount'] ?? 0,
        };
      }).toList();

      // Add pending orders as deliveries that need assignment
      for (final order in unassignedOrders) {
        processedDeliveries.add({
          'id': 'pending_${order['id']}',
          'order_id': order['id'],
          'customer_name': order['customer_name'] ?? 'Unknown',
          'customer_address': order['delivery_address'] ?? '',
          'rider_id': null,
          'rider_name': 'Not Assigned',
          'status': 'pending',
          'estimated_delivery': 'Not assigned',
          'order_total': order['total_amount'] ?? 0,
        });
      }

      setState(() {
        _riders = processedRiders;
        _activeDeliveries = processedDeliveries;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading delivery data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _calculateEstimatedTime(String? estimatedTime) {
    if (estimatedTime == null) return 'Unknown';

    try {
      final deliveryTime = DateTime.parse(estimatedTime);
      final now = DateTime.now();
      final difference = deliveryTime.difference(now);

      if (difference.isNegative) return 'Overdue';

      final minutes = difference.inMinutes;
      if (minutes < 60) {
        return '$minutes mins';
      } else {
        final hours = difference.inHours;
        return '$hours hrs';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      // Use drawer for mobile/tablet, sidebar for desktop
      drawer: isMobile || isTablet
          ? Drawer(
              backgroundColor: Colors.white,
              child: const AdminSidebar(currentRoute: '/admin-delivery'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "🚚 Delivery",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.orange),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  onPressed: _showAddRiderDialog,
                  tooltip: 'Add Rider',
                ),
              ],
            )
          : null,
      body: isMobile || isTablet
          ? _buildMobileTabletContent()
          : _buildDesktopContent(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Sidebar for desktop
        const AdminSidebar(currentRoute: '/admin-delivery'),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "🚚 Delivery Management",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddRiderDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Active Deliveries
                            _buildActiveDeliveries(),

                            const SizedBox(height: 32),

                            // Riders Management
                            _buildRidersManagement(),

                            const SizedBox(height: 32),

                            // Delivery Zones
                            _buildDeliveryZones(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Rider Button at top for mobile
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddRiderDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Rider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active Deliveries
          _buildActiveDeliveries(),

          const SizedBox(height: 24),

          // Riders Management
          _buildRidersManagement(),

          const SizedBox(height: 24),

          // Delivery Zones
          _buildDeliveryZones(),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveries() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Active Deliveries',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_activeDeliveries.length} active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_activeDeliveries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No active deliveries',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              ),
            )
          else
            ..._activeDeliveries.map(
              (delivery) => _buildDeliveryItem(delivery),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(Map<String, dynamic> delivery) {
    Color statusColor;
    switch (delivery['status']) {
      case 'picked_up':
        statusColor = Colors.blue;
        break;
      case 'on_the_way':
        statusColor = Colors.orange;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delivery_dining, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${delivery['order_id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delivery['customer_name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery['customer_address'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDeliveryStatus(delivery['status']),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (delivery['rider_id'] != null)
                Text(
                  delivery['rider_name'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _assignRiderToOrder(delivery['order_id']),
                  icon: const Icon(Icons.person_add, size: 12),
                  label: const Text('Assign Rider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 24),
                    textStyle: GoogleFonts.poppins(fontSize: 10),
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                delivery['rider_id'] != null
                    ? 'ETA: ${delivery['estimated_delivery']}'
                    : 'Not assigned',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: delivery['rider_id'] != null
                      ? Colors.orange
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (delivery['rider_id'] != null)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _startLocationTracking(
                        delivery['rider_id'],
                        delivery['order_id'],
                      ),
                      icon: const Icon(Icons.play_arrow, size: 12),
                      label: const Text('Start Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 24),
                        textStyle: GoogleFonts.poppins(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _stopLocationTracking,
                      icon: const Icon(Icons.stop, size: 12),
                      label: const Text('Stop Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 24),
                        textStyle: GoogleFonts.poppins(fontSize: 10),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRidersManagement() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Delivery Riders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ..._riders.map((rider) => _buildRiderItem(rider)),
        ],
      ),
    );
  }

  Widget _buildRiderItem(Map<String, dynamic> rider) {
    Color statusColor;
    switch (rider['status']) {
      case 'available':
        statusColor = Colors.green;
        break;
      case 'busy':
        statusColor = Colors.orange;
        break;
      case 'offline':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.orange.shade100,
            child: Text(
              rider['name'].substring(0, 1),
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rider['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rider['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rider['phone'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      rider['current_location'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    rider['rating'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${rider['total_deliveries']} deliveries',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                rider['vehicle_type'],
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryZones() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Zones',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: Colors.orange, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Delivery Zones Map',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interactive map will be implemented here',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRiderForm(
    BuildContext dialogContext,
    StateSetter setState,
  ) async {
    if (!_riderFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare rider data
      final riderData = {
        'name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'vehicle_type': _selectedVehicleType,
        'license_number': _licenseController.text.trim(),
        'is_active': true,
      };

      // Add profile image if provided
      if (_profileImageController.text.trim().isNotEmpty) {
        riderData['profile_image'] = _profileImageController.text.trim();
      }

      // Insert into Supabase
      await Supabase.instance.client
          .from('delivery_personnel')
          .insert(riderData);

      // Close dialog and show success message
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload delivery data to show the new rider
      _loadDeliveryData();
    } catch (e) {
      print('Error adding rider: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add rider: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showAddRiderDialog() {
    // Reset form state
    _riderFormKey.currentState?.reset();
    _fullNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _licenseController.clear();
    _profileImageController.clear();
    _selectedVehicleType = 'bike';
    _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add New Rider',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 500,
              child: Form(
                key: _riderFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Register New Delivery Rider',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Personal Information',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter rider\'s full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'rider@example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email address is required';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1234567890',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Information Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vehicle Information',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.directions_bike,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['bike', 'scooter', 'car'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                type == 'bike'
                                    ? Icons.directions_bike
                                    : type == 'scooter'
                                    ? Icons.electric_scooter
                                    : Icons.directions_car,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(type.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedVehicleType = value!);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a vehicle type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: 'License Number',
                        hintText: 'DL-12345',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.badge,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'License number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Profile Image Section (Optional)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Profile Image (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _profileImageController,
                      decoration: InputDecoration(
                        labelText: 'Profile Image URL',
                        hintText: 'https://example.com/image.jpg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.image,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Leave empty to use default avatar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitRiderForm(context, setState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Rider'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeliveryStatus(String status) {
    switch (status) {
      case 'picked_up':
        return 'Picked Up';
      case 'on_the_way':
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _assignRiderToOrder(String orderId) async {
    try {
      final assignedRiderId = await SupabaseService.assignDeliveryPerson(
        orderId,
      );

      if (assignedRiderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload delivery data to show the assignment
        _loadDeliveryData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available riders found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error assigning rider: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign rider: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startLocationTracking(String riderId, String orderId) async {
    try {
      await DeliveryLocationService().startLocationTracking(riderId, orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking started for rider'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error starting location tracking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopLocationTracking() async {
    try {
      await DeliveryLocationService().stopLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking stopped'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error stopping location tracking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
