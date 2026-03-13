import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/admin_sidebar.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Today';

  final List<String> _periods = ['Today', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      setState(() => _isLoading = true);

      // Get all orders for analysis
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading reports data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    return _orders.where((order) {
      final orderDate = DateTime.parse(order['created_at']);
      return orderDate.isAfter(startDate) ||
          orderDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  double get _totalRevenue => _filteredOrders.fold(0.0, (sum, order) {
    final price = order['total_amount'] ?? order['total_price'];
    if (price is num) {
      return sum + price.toDouble();
    }
    return sum;
  });

  int get _totalOrders => _filteredOrders.length;

  double get _averageOrderValue =>
      _totalOrders > 0 ? _totalRevenue / _totalOrders : 0.0;

  Map<String, int> get _ordersByStatus {
    final statusCount = <String, int>{};
    for (final order in _filteredOrders) {
      final status = order['status'] as String;
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    return statusCount;
  }

  Map<String, double> get _revenueByDay {
    final revenueByDay = <String, double>{};
    for (final order in _filteredOrders) {
      final date = DateTime.parse(order['created_at']);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final price = order['total_amount'] ?? order['total_price'];
      if (price is num) {
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + price.toDouble();
      }
    }
    return revenueByDay;
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
              child: const AdminSidebar(currentRoute: '/admin-reports'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "📊 Reports",
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
                // Period Selector for mobile
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    underline: const SizedBox(),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(
                          period,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: _loadReportsData,
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
        const AdminSidebar(currentRoute: '/admin-reports'),

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
                      "📊 Sales Reports & Analytics",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    // Period Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPeriod = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: _loadReportsData,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ),

              // Reports Content
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
                            // Key Metrics Cards
                            _buildMetricsCards(),

                            const SizedBox(height: 32),

                            // Revenue Chart Placeholder
                            _buildRevenueChart(),

                            const SizedBox(height: 32),

                            // Order Status Breakdown
                            _buildOrderStatusChart(),

                            const SizedBox(height: 32),

                            // Top Performing Items
                            _buildTopItems(),

                            const SizedBox(height: 32),

                            // Recent Orders Summary
                            _buildRecentOrdersSummary(),
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
          // Key Metrics Cards - responsive
          _buildMetricsCards(),

          const SizedBox(height: 24),

          // Revenue Chart Placeholder
          _buildRevenueChart(),

          const SizedBox(height: 24),

          // Order Status Breakdown
          _buildOrderStatusChart(),

          const SizedBox(height: 24),

          // Top Performing Items
          _buildTopItems(),

          const SizedBox(height: 24),

          // Recent Orders Summary
          _buildRecentOrdersSummary(),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      // Stack cards vertically on mobile
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Revenue',
                  'Rs. ${_totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                  '+12% from last ${_selectedPeriod.toLowerCase()}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  _totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                  '+8% from last ${_selectedPeriod.toLowerCase()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Order Value',
                  'Rs. ${_averageOrderValue.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.orange,
                  '+5% from last ${_selectedPeriod.toLowerCase()}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  _totalOrders > 0
                      ? '${(_ordersByStatus['delivered'] ?? 0) * 100 ~/ _totalOrders}%'
                      : '0%',
                  Icons.check_circle,
                  Colors.purple,
                  'Orders delivered successfully',
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Use horizontal layout for tablet/desktop
      return Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Total Revenue',
              'Rs. ${_totalRevenue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
              '+12% from last ${_selectedPeriod.toLowerCase()}',
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              'Total Orders',
              _totalOrders.toString(),
              Icons.shopping_cart,
              Colors.blue,
              '+8% from last ${_selectedPeriod.toLowerCase()}',
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              'Average Order Value',
              'Rs. ${_averageOrderValue.toStringAsFixed(0)}',
              Icons.trending_up,
              Colors.orange,
              '+5% from last ${_selectedPeriod.toLowerCase()}',
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              'Completion Rate',
              _totalOrders > 0
                  ? '${(_ordersByStatus['delivered'] ?? 0) * 100 ~/ _totalOrders}%'
                  : '0%',
              Icons.check_circle,
              Colors.purple,
              'Orders delivered successfully',
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade400, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
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
          Text(
            'Revenue Trend',
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
                  Icon(Icons.show_chart, color: Colors.orange, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Revenue Chart',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chart visualization will be implemented here',
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
    );
  }

  Widget _buildOrderStatusChart() {
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
          Text(
            'Order Status Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._ordersByStatus.entries.map((entry) {
            final percentage = _totalOrders > 0
                ? (entry.value * 100 ~/ _totalOrders)
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatStatusText(entry.key),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value} orders',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _totalOrders > 0
                                    ? entry.value / _totalOrders
                                    : 0.0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStatusColor(entry.key),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatStatusText(entry.key),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${entry.value} orders',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _totalOrders > 0
                                          ? entry.value / _totalOrders
                                          : 0.0,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getStatusColor(entry.key),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$percentage%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopItems() {
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
          Text(
            'Top Performing Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.orange, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Top Items Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Item performance metrics will be shown here',
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
    );
  }

  Widget _buildRecentOrdersSummary() {
    final recentOrders = _filteredOrders.take(5).toList();

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Orders Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            NavigationHelper.safePush(context, '/admin-orders'),
                        child: Text(
                          'View All Orders',
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Text(
                      'Recent Orders Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          NavigationHelper.safePush(context, '/admin-orders'),
                      child: Text(
                        'View All Orders',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          if (recentOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No orders in selected period',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              ),
            )
          else
            ...recentOrders.map((order) => _buildRecentOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildRecentOrderItem(Map<String, dynamic> order) {
    final createdAt = DateTime.parse(order['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(order['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_cart,
              color: _getStatusColor(order['status']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${((order['total_amount'] ?? order['total_price']) ?? 0).toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'on the way':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'on the way':
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
