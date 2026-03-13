import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_sidebar.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('users')
          .select(
            'id, full_name, email, phone, address, created_at, role, is_banned',
          )
          .eq('role', 'customer')
          .order('created_at', ascending: false);

      print('Customers fetched: ${response.length}');

      // Calculate order statistics for each customer
      final customersWithStats = <Map<String, dynamic>>[];

      for (final customer in response) {
        final customerMap = Map<String, dynamic>.from(customer);

        try {
          // Get order count and total spent for this user
          final ordersResponse = await Supabase.instance.client
              .from('orders')
              .select('total_price')
              .eq('user_id', customer['id']);

          final orderCount = ordersResponse.length;
          double totalSpent = 0.0;
          for (final order in ordersResponse) {
            totalSpent += (order['total_price'] as num?)?.toDouble() ?? 0.0;
          }

          customerMap['order_count'] = orderCount;
          customerMap['total_spent'] = totalSpent;
        } catch (orderError) {
          customerMap['order_count'] = 0;
          customerMap['total_spent'] = 0.0;
        }

        customersWithStats.add(customerMap);
      }

      setState(() {
        _customers = customersWithStats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading customers: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      final name = customer['full_name']?.toLowerCase() ?? '';
      final email = customer['email']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
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
              child: const AdminSidebar(currentRoute: '/admin-customers'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "👥 Customers",
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
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: _loadCustomers,
                  tooltip: 'Refresh',
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
        const AdminSidebar(currentRoute: '/admin-customers'),

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
                      "👥 Customer Management",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredCustomers.length} customers',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filters
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by full name or email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _loadCustomers,
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              // Customer Stats
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total Customers',
                      _customers.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    const SizedBox(width: 20),
                    _buildStatCard(
                      'Active Customers',
                      _customers
                          .where((c) => (c['order_count'] as int) > 0)
                          .length
                          .toString(),
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                    const SizedBox(width: 20),
                    _buildStatCard(
                      'Total Orders',
                      _customers
                          .fold<int>(
                            0,
                            (sum, c) => sum + (c['order_count'] as int),
                          )
                          .toString(),
                      Icons.receipt,
                      Colors.purple,
                    ),
                    const SizedBox(width: 20),
                    _buildStatCard(
                      'Total Revenue',
                      'Rs. ${_customers.fold<double>(0.0, (sum, c) => sum + (c['total_spent'] as double)).toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ],
                ),
              ),

              // Customers List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        color: Colors.orange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            return _buildCustomerCard(
                              _filteredCustomers[index],
                            );
                          },
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
    return Column(
      children: [
        // Search and Filters - responsive
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by full name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_filteredCustomers.length} customers',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadCustomers,
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Customer Stats - responsive grid
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      _customers.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Customers',
                      _customers
                          .where((c) => (c['order_count'] as int) > 0)
                          .length
                          .toString(),
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      _customers
                          .fold<int>(
                            0,
                            (sum, c) => sum + (c['order_count'] as int),
                          )
                          .toString(),
                      Icons.receipt,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Revenue',
                      'Rs. ${_customers.fold<double>(0.0, (sum, c) => sum + (c['total_spent'] as double)).toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Customers List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _filteredCustomers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerCard(_filteredCustomers[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customers will appear here once they register',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final orderCount = customer['order_count'] as int;
    final totalSpent = customer['total_spent'] as double;
    final createdAt = DateTime.parse(customer['created_at']);
    final memberSince = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    final isBanned = customer['is_banned'] as bool? ?? false;

    // Determine customer tier
    String tier;
    Color tierColor;
    if (totalSpent >= 5000) {
      tier = 'Gold';
      tierColor = Colors.amber;
    } else if (totalSpent >= 2000) {
      tier = 'Silver';
      tierColor = Colors.grey;
    } else if (totalSpent >= 500) {
      tier = 'Bronze';
      tierColor = Colors.brown;
    } else {
      tier = 'New';
      tierColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBanned ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBanned
            ? Border.all(color: Colors.red.shade200, width: 1)
            : null,
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (customer['full_name'] as String?)
                          ?.substring(0, 1)
                          .toUpperCase() ??
                      'U',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer['full_name'] ?? 'Unknown User',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isBanned
                                ? Colors.red.shade700
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tier,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: tierColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isBanned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            'BANNED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer['email'] ?? 'No email',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member since: $memberSince',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$orderCount orders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${totalSpent.toStringAsFixed(0)} spent',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _showCustomerDetails(customer),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _toggleBanStatus(customer['id'], isBanned),
                      icon: Icon(
                        isBanned ? Icons.lock_open : Icons.block,
                        size: 14,
                      ),
                      label: Text(
                        isBanned ? 'Unban' : 'Ban',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBanned ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (customer['full_name'] as String?)
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['full_name'] ?? 'Unknown User',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          customer['email'] ?? 'No email',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditCustomerDialog(customer),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Customer',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer Stats
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStat(
                      'Total Orders',
                      (customer['order_count'] as int).toString(),
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailStat(
                      'Total Spent',
                      'Rs. ${(customer['total_spent'] as double).toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailStat(
                      'Phone',
                      customer['phone'] ?? 'Not provided',
                      Icons.phone,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailStat(
                      'Address',
                      customer['address'] ?? 'Not provided',
                      Icons.location_on,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Orders (placeholder)
              Text(
                'Recent Orders',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Order history will be displayed here',
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    final fullNameController = TextEditingController(
      text: customer['full_name'] ?? '',
    );
    final addressController = TextEditingController(
      text: customer['address'] ?? '',
    );
    final phoneController = TextEditingController(
      text: customer['phone'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateCustomer(
              customer['id'],
              fullNameController.text.trim(),
              addressController.text.trim(),
              phoneController.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCustomer(
    String id,
    String fullName,
    String address,
    String phone,
  ) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'full_name': fullName, 'address': address, 'phone': phone})
          .eq('id', id);

      Navigator.pop(context); // Close edit dialog
      Navigator.pop(context); // Close details dialog
      _loadCustomers(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated successfully')),
      );
    } catch (e) {
      print('❌ Error updating customer: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating customer: $e')));
    }
  }

  Future<void> _toggleBanStatus(String userId, bool isCurrentlyBanned) async {
    try {
      final newBanStatus = !isCurrentlyBanned;

      await Supabase.instance.client
          .from('users')
          .update({'is_banned': newBanStatus})
          .eq('id', userId);

      _loadCustomers(); // Refresh list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newBanStatus
                ? 'User has been banned successfully'
                : 'User has been unbanned successfully',
          ),
          backgroundColor: newBanStatus ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error toggling ban status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating ban status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
