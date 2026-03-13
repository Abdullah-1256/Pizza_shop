import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/supabase_client.dart';
import '../widgets/admin_sidebar.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  List<Map<String, dynamic>> _todayOrders = [];
  bool _isLoading = true;
  double _totalSales = 0.0;
  Map<String, double> _paymentAnalytics = {};
  Map<String, int> _paymentOrderCounts = {};
  Timer? _autoRefreshTimer;
  DateTime _lastRefreshTime = DateTime.now();

  // Customer Analytics
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  Map<String, int> _customerRoleCounts = {};
  int _totalCustomers = 0;

  // Customer Filtering & Pagination
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    print('🎯 AdminAnalyticsPage initState called');
    _loadAnalyticsData();
    // Temporarily disable auto-refresh to prevent layout issues
    // _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    print('⏰ Starting auto-refresh timer (5 minutes interval)');
    // Auto-refresh every 5 minutes (300 seconds) to avoid rapid updates
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 300), (timer) {
      print('🔄 Auto-refresh timer triggered at ${DateTime.now()}');
      if (mounted) {
        print('🔄 Calling _loadAnalyticsData() from timer');
        _loadAnalyticsData();
      } else {
        print('🔄 Widget not mounted, skipping refresh');
      }
    });
  }

  Future<void> _loadAnalyticsData() async {
    print('🚀 _loadAnalyticsData() called at ${DateTime.now()}');
    try {
      setState(() => _isLoading = true);

      // Load orders data
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final orders = await SupabaseService.getOrders();
      print('📦 Orders loaded: ${orders.length}');

      _todayOrders = orders.where((order) {
        final orderDate = DateTime.parse(order['created_at']);
        return orderDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
            orderDate.isBefore(tomorrow);
      }).toList();
      print('📅 Today orders filtered: ${_todayOrders.length}');

      // Load customer data
      print('👥 About to call _loadCustomerData()...');
      await _loadCustomerData();
      print('✅ _loadCustomerData() completed');

      _calculateAnalytics();
      setState(() {
        _isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
      print('🎉 Analytics data loading completed successfully');
    } catch (e) {
      print('❌ Error loading analytics data: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomerData() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('id, full_name, email, phone, address, created_at, role')
          .eq('role', 'customer')
          .order('created_at', ascending: false);

      print('Customers fetched: ${response.length}');

      _processCustomerData(response);
    } catch (e) {
      print('❌ Error loading customer data: $e');
    }
  }

  void _processCustomerData(dynamic response) {
    // Debug: Print all profiles with their roles
    final allRoles = <String>{};
    for (final profile in response) {
      final role = profile['role']?.toString() ?? 'null';
      allRoles.add(role);
      print(
        '👤 Profile: ${profile['full_name'] ?? profile['email']} - Role: $role - ID: ${profile['id']}',
      );
    }
    print('🎭 All unique roles found in database: $allRoles');

    // Filter customers by role (case-insensitive)
    _allCustomers = List<Map<String, dynamic>>.from(response).where((profile) {
      final role = (profile['role'] ?? 'customer').toString().toLowerCase();
      return role == 'customer';
    }).toList();

    print('✅ Filtered customers with role="customer": ${_allCustomers.length}');

    // Count customers by role
    _customerRoleCounts = {};
    _totalCustomers = _allCustomers.length;

    for (final customer in _allCustomers) {
      final role = (customer['role'] ?? 'customer').toString().toLowerCase();
      _customerRoleCounts[role] = (_customerRoleCounts[role] ?? 0) + 1;
      print(
        '👤 Customer: ${customer['full_name'] ?? customer['email']} - Role: $role - ID: ${customer['id']}',
      );
    }

    print('📊 Customer role counts: $_customerRoleCounts');
    print('✅ Total customers loaded: $_totalCustomers');

    _applyFiltersAndPagination();
  }

  void _applyFiltersAndPagination() {
    print('🔍 _applyFiltersAndPagination() called');
    print('📊 _allCustomers length: ${_allCustomers.length}');
    print('🎯 _selectedRole: $_selectedRole');
    print('🔎 _searchQuery: "$_searchQuery"');

    // Filter by role
    List<Map<String, dynamic>> filtered = _allCustomers;
    if (_selectedRole != 'all') {
      filtered = filtered.where((customer) {
        final role = customer['role'] ?? 'user';
        return role == _selectedRole;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        final name = (customer['full_name'] ?? '').toLowerCase();
        final email = (customer['email'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    print('📋 After filtering: ${filtered.length} customers');

    // Sort
    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'name':
          aValue = (a['full_name'] ?? a['email'] ?? '').toLowerCase();
          bValue = (b['full_name'] ?? b['email'] ?? '').toLowerCase();
          break;
        case 'email':
          aValue = (a['email'] ?? '').toLowerCase();
          bValue = (b['email'] ?? '').toLowerCase();
          break;
        case 'created_at':
        default:
          aValue = DateTime.parse(a['created_at']);
          bValue = DateTime.parse(b['created_at']);
          break;
      }

      if (_sortOrder == 'asc') {
        return aValue.compareTo(bValue);
      } else {
        return bValue.compareTo(aValue);
      }
    });

    // Calculate pagination
    _totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;

    // Apply pagination
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    _filteredCustomers = filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );

    print(
      '📄 Pagination: page $_currentPage of $_totalPages, showing ${_filteredCustomers.length} items',
    );
    print(
      '👥 _filteredCustomers: ${_filteredCustomers.map((c) => c['full_name'] ?? c['email']).toList()}',
    );

    setState(() {});
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page
    _applyFiltersAndPagination();
  }

  void _onRoleChanged(String role) {
    _selectedRole = role;
    _currentPage = 1; // Reset to first page
    _applyFiltersAndPagination();
  }

  void _onSortChanged(String sortBy, String order) {
    _sortBy = sortBy;
    _sortOrder = order;
    _currentPage = 1; // Reset to first page
    _applyFiltersAndPagination();
  }

  void _onItemsPerPageChanged(int items) {
    _itemsPerPage = items;
    _currentPage = 1; // Reset to first page
    _applyFiltersAndPagination();
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    _applyFiltersAndPagination();
  }

  void _calculateAnalytics() {
    _totalSales = 0.0;
    _paymentAnalytics = {};
    _paymentOrderCounts = {};

    for (final order in _todayOrders) {
      final amount = (order['total_amount'] ?? order['total_price'] ?? 0)
          .toDouble();
      _totalSales += amount;

      // Get payment method - map to JazzCash/Bank/Cash
      final paymentMethodId = order['payment_method_id'];
      String paymentType = 'Cash'; // Default

      if (paymentMethodId != null) {
        // Simplified mapping - in real app, you'd fetch payment method details
        if (paymentMethodId.toString().contains('paypal') ||
            paymentMethodId.toString().contains('jazzcash')) {
          paymentType = 'JazzCash';
        } else if (paymentMethodId.toString().contains('card') ||
            paymentMethodId.toString().contains('bank')) {
          paymentType = 'Bank Account';
        }
      }

      _paymentAnalytics[paymentType] =
          (_paymentAnalytics[paymentType] ?? 0) + amount;
      _paymentOrderCounts[paymentType] =
          (_paymentOrderCounts[paymentType] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 Building AdminAnalyticsPage UI');
    print(
      '📊 Current state: _allCustomers=${_allCustomers.length}, _filteredCustomers=${_filteredCustomers.length}, _isLoading=$_isLoading',
    );

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
              child: const AdminSidebar(currentRoute: '/admin-analytics'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "💰 Analytics",
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
                  onPressed: _loadAnalyticsData,
                  tooltip: 'Refresh Data',
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
        const AdminSidebar(currentRoute: '/admin-analytics'),

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
                      "💰 Payment Analytics",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: _loadAnalyticsData,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ),

              // Analytics Content
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
                            // Today's Summary
                            _buildTodaySummary(),

                            const SizedBox(height: 32),

                            // Payment Analytics Table
                            _buildPaymentAnalyticsTable(),

                            const SizedBox(height: 32),

                            // Customer Analytics
                            _buildCustomerAnalytics(),

                            const SizedBox(height: 32),

                            // Real-time Status
                            _buildRealtimeStatus(),
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
          // Today's Summary
          _buildTodaySummary(),

          const SizedBox(height: 24),

          // Payment Analytics Table - responsive
          _buildPaymentAnalyticsTable(),

          const SizedBox(height: 24),

          // Customer Analytics
          _buildCustomerAnalytics(),

          const SizedBox(height: 24),

          // Real-time Status
          _buildRealtimeStatus(),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.today, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Today\'s Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Get screen size for responsive design
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              if (isMobile) {
                return Column(
                  children: [
                    _buildSummaryCard(
                      'Total Sales',
                      'Rs. ${_totalSales.toStringAsFixed(0)}',
                      Colors.green,
                      Icons.attach_money,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Total Orders',
                      _todayOrders.length.toString(),
                      Colors.blue,
                      Icons.shopping_cart,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Avg. Order Value',
                      _todayOrders.isNotEmpty
                          ? 'Rs. ${(_totalSales / _todayOrders.length).toStringAsFixed(0)}'
                          : 'Rs. 0',
                      Colors.purple,
                      Icons.trending_up,
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Sales',
                        'Rs. ${_totalSales.toStringAsFixed(0)}',
                        Colors.green,
                        Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Orders',
                        _todayOrders.length.toString(),
                        Colors.blue,
                        Icons.shopping_cart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Avg. Order Value',
                        _todayOrders.isNotEmpty
                            ? 'Rs. ${(_totalSales / _todayOrders.length).toStringAsFixed(0)}'
                            : 'Rs. 0',
                        Colors.purple,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAnalyticsTable() {
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
                Icon(Icons.payment, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Payment Method Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Amount',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Orders',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Percentage',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                ..._paymentAnalytics.entries.map((entry) {
                  final orderCount = _paymentOrderCounts[entry.key] ?? 0;
                  final percentage = _totalSales > 0
                      ? (entry.value * 100 / _totalSales).toStringAsFixed(1)
                      : '0.0';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(
                                entry.key == 'JazzCash'
                                    ? Icons.account_balance_wallet
                                    : entry.key == 'Bank Account'
                                    ? Icons.credit_card
                                    : Icons.money,
                                color: entry.key == 'JazzCash'
                                    ? Colors.blue
                                    : entry.key == 'Bank Account'
                                    ? Colors.purple
                                    : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Rs. ${entry.value.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            orderCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$percentage%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Total Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Rs. ${_totalSales.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _todayOrders.length.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '100.0%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAnalytics() {
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
                Icon(Icons.people, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Customer Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Debug info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'All: ${_allCustomers.length} | Filtered: ${_filteredCustomers.length}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Debug section for when no customers found
          if (_allCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Text(
                      'No customers found!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check console logs for detailed debugging information.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            // Customer Summary Cards - responsive
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildCustomerSummaryCard(
                          'Total Customers',
                          _totalCustomers.toString(),
                          Colors.blue,
                          Icons.group,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomerSummaryCard(
                          'Customers',
                          _customerRoleCounts['customer']?.toString() ?? '0',
                          Colors.green,
                          Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomerSummaryCard(
                          'Admins',
                          _customerRoleCounts['admin']?.toString() ?? '0',
                          Colors.red,
                          Icons.admin_panel_settings,
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildCustomerSummaryCard(
                            'Total Customers',
                            _totalCustomers.toString(),
                            Colors.blue,
                            Icons.group,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCustomerSummaryCard(
                            'Customers',
                            _customerRoleCounts['customer']?.toString() ?? '0',
                            Colors.green,
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCustomerSummaryCard(
                            'Admins',
                            _customerRoleCounts['admin']?.toString() ?? '0',
                            Colors.red,
                            Icons.admin_panel_settings,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

          const SizedBox(height: 20),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),

                const SizedBox(height: 16),

                // Filters Row - responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 768;
                    if (isMobile) {
                      return Column(
                        children: [
                          // First row: Role and Sort By
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Role',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                        'All Roles',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text(
                                        'Admin',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'customer',
                                      child: Text(
                                        'Customer',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Text(
                                        'User',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      _onRoleChanged(value ?? 'all'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _sortBy,
                                  decoration: InputDecoration(
                                    labelText: 'Sort By',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'created_at',
                                      child: Text(
                                        'Join Date',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'name',
                                      child: Text(
                                        'Name',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'email',
                                      child: Text(
                                        'Email',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) => _onSortChanged(
                                    value ?? 'created_at',
                                    _sortOrder,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Second row: Order and Per Page
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _sortOrder,
                                  decoration: InputDecoration(
                                    labelText: 'Order',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'desc',
                                      child: Text(
                                        'Newest First',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'asc',
                                      child: Text(
                                        'Oldest First',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      _onSortChanged(_sortBy, value ?? 'desc'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _itemsPerPage,
                                  decoration: InputDecoration(
                                    labelText: 'Per Page',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 5,
                                      child: Text(
                                        '5',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 10,
                                      child: Text(
                                        '10',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 20,
                                      child: Text(
                                        '20',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 50,
                                      child: Text(
                                        '50',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      _onItemsPerPageChanged(value ?? 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          // Role Filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text(
                                    'All Roles',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text(
                                    'Admin',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'customer',
                                  child: Text(
                                    'Customer',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text(
                                    'User',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  _onRoleChanged(value ?? 'all'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Sort By
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: InputDecoration(
                                labelText: 'Sort By',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'created_at',
                                  child: Text(
                                    'Join Date',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text(
                                    'Name',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'email',
                                  child: Text(
                                    'Email',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                              onChanged: (value) => _onSortChanged(
                                value ?? 'created_at',
                                _sortOrder,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Sort Order
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortOrder,
                              decoration: InputDecoration(
                                labelText: 'Order',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'desc',
                                  child: Text(
                                    'Newest First',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'asc',
                                  child: Text(
                                    'Oldest First',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  _onSortChanged(_sortBy, value ?? 'desc'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Items Per Page
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _itemsPerPage,
                              decoration: InputDecoration(
                                labelText: 'Per Page',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 5,
                                  child: Text(
                                    '5',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 10,
                                  child: Text(
                                    '10',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 20,
                                  child: Text(
                                    '20',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 50,
                                  child: Text(
                                    '50',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  _onItemsPerPageChanged(value ?? 10),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Customer Details Table
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Customer Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Role',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Joined',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Rows (filtered and paginated)
                ..._filteredCustomers.map((customer) {
                  try {
                    final createdAt = DateTime.parse(customer['created_at']);
                    final joinedDate =
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}';
                    final role = customer['role'] ?? 'user';

                    return Container(
                      key: ValueKey(
                        customer['id'],
                      ), // Add key for stable rendering
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize:
                                  MainAxisSize.min, // Prevent infinite height
                              children: [
                                Text(
                                  customer['full_name'] ??
                                      customer['email'] ??
                                      'Unknown',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  customer['email'] ?? '',
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
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRoleColor(role).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _formatRoleText(role),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getRoleColor(role),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              joinedDate,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    // Return error row if data parsing fails
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.red.shade200),
                        ),
                        color: Colors.red.shade50,
                      ),
                      child: Text(
                        'Error loading customer data',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                }),

                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Results info
                      Text(
                        'Showing ${_filteredCustomers.isEmpty ? 0 : ((_currentPage - 1) * _itemsPerPage) + 1} to ${((_currentPage - 1) * _itemsPerPage) + _filteredCustomers.length} of ${_allCustomers.where((c) {
                          if (_selectedRole != 'all') {
                            final role = c['role'] ?? 'user';
                            return role == _selectedRole;
                          }
                          if (_searchQuery.isNotEmpty) {
                            final name = (c['full_name'] ?? '').toLowerCase();
                            final email = (c['email'] ?? '').toLowerCase();
                            final query = _searchQuery.toLowerCase();
                            return name.contains(query) || email.contains(query);
                          }
                          return true;
                        }).length} entries',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                      // Pagination controls
                      Row(
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () => _onPageChanged(_currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left, size: 20),
                            color: _currentPage > 1
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              '$_currentPage / $_totalPages',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _currentPage < _totalPages
                                ? () => _onPageChanged(_currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right, size: 20),
                            color: _currentPage < _totalPages
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.green;
      case 'customer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      case 'customer':
        return 'Customer';
      default:
        return role.toUpperCase();
    }
  }

  Widget _buildRealtimeStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Real-time Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Data updated in real-time. Last refresh: ${_lastRefreshTime.toString().substring(11, 19)}',
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadAnalyticsData,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
