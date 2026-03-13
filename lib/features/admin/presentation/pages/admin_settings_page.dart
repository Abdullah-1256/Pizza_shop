import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/network/supabase_client.dart';
import '../widgets/admin_sidebar.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  // Business Settings
  final TextEditingController _businessNameController = TextEditingController(
    text: 'Pizza Time',
  );
  final TextEditingController _businessEmailController = TextEditingController(
    text: 'admin@pizzatime.com',
  );
  final TextEditingController _businessPhoneController = TextEditingController(
    text: '+92 300 1234567',
  );
  final TextEditingController _deliveryFeeController = TextEditingController(
    text: '150',
  );
  final TextEditingController _minOrderAmountController = TextEditingController(
    text: '500',
  );
  final TextEditingController _taxRateController = TextEditingController(
    text: '5',
  );

  // Restaurant Status
  bool _restaurantStatus = true; // true = open, false = closed

  // Daily Sales Data
  List<Map<String, dynamic>> _todayOrders = [];
  double _totalSales = 0.0;
  Map<String, double> _paymentAnalytics = {};

  // Operating Hours
  TimeOfDay _openingTime = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 23, minute: 0);
  bool _isOpen247 = false;

  // Notification Settings
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _pushNotifications = true;

  // Security Settings
  bool _twoFactorAuth = false;
  bool _sessionTimeout = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _deliveryFeeController.dispose();
    _minOrderAmountController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      // Load settings from Supabase
      final settings = await Supabase.instance.client
          .from('settings')
          .select()
          .single();

      if (settings != null) {
        setState(() {
          _deliveryFeeController.text = (settings['delivery_charges'] ?? 150)
              .toString();
          _minOrderAmountController.text = (settings['min_order_amount'] ?? 500)
              .toString();
          _businessPhoneController.text =
              settings['contact_number'] ?? '+92 300 1234567';
          _restaurantStatus = settings['restaurant_status'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Keep default values if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving settings...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Call the update_settings RPC function
      await Supabase.instance.client.rpc(
        'update_settings',
        params: {
          'p_delivery_charges': int.parse(_deliveryFeeController.text),
          'p_min_order_amount': int.parse(_minOrderAmountController.text),
          'p_contact_number': _businessPhoneController.text,
          'p_restaurant_status': _restaurantStatus,
        },
      );

      // If restaurant is being closed, show daily sales summary
      if (!_restaurantStatus) {
        await _loadTodayOrders();
        _showDailySalesDialog();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadTodayOrders() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final orders = await SupabaseService.getOrders();

      _todayOrders = orders.where((order) {
        final orderDate = DateTime.parse(order['created_at']);
        return orderDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
            orderDate.isBefore(tomorrow);
      }).toList();

      _calculateSalesAnalytics();
    } catch (e) {
      print('Error loading today orders: $e');
    }
  }

  void _calculateSalesAnalytics() {
    _totalSales = 0.0;
    _paymentAnalytics = {};

    for (final order in _todayOrders) {
      final amount = (order['total_amount'] ?? order['total_price'] ?? 0)
          .toDouble();
      _totalSales += amount;

      // Get payment method - for simplicity, map to JazzCash/Bank/Cash
      final paymentMethodId = order['payment_method_id'];
      String paymentType = 'Cash'; // Default

      if (paymentMethodId != null) {
        // This is a simplified mapping - in real app, you'd fetch payment method details
        // For now, assume paypal = JazzCash, card = Bank Account, cash = Cash
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
    }
  }

  void _showDailySalesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Daily Sales Summary',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Sales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Sales Today',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Rs. ${_totalSales.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Analytics Table
              Text(
                'Payment Method Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                        ],
                      ),
                    ),

                    // Table Rows
                    ..._paymentAnalytics.entries.map((entry) {
                      final orderCount = _todayOrders.where((order) {
                        final paymentMethodId = order['payment_method_id'];
                        String paymentType = 'Cash';
                        if (paymentMethodId != null) {
                          if (paymentMethodId.toString().contains('paypal') ||
                              paymentMethodId.toString().contains('jazzcash')) {
                            paymentType = 'JazzCash';
                          } else if (paymentMethodId.toString().contains(
                                'card',
                              ) ||
                              paymentMethodId.toString().contains('bank')) {
                            paymentType = 'Bank Account';
                          }
                        }
                        return paymentType == entry.key;
                      }).length;

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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
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
              child: const AdminSidebar(currentRoute: '/admin-settings'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "⚙️ Settings",
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
                  icon: const Icon(Icons.save, color: Colors.green),
                  onPressed: _saveSettings,
                  tooltip: 'Save Changes',
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
        const AdminSidebar(currentRoute: '/admin-settings'),

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
                      "⚙️ Admin Settings",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Information
                      _buildSettingsSection(
                        'Business Information',
                        Icons.business,
                        _buildBusinessInfoSection(),
                      ),

                      const SizedBox(height: 32),

                      // Pricing Settings
                      _buildSettingsSection(
                        'Pricing & Fees',
                        Icons.attach_money,
                        _buildPricingSection(),
                      ),

                      const SizedBox(height: 32),

                      // Operating Hours
                      _buildSettingsSection(
                        'Operating Hours',
                        Icons.schedule,
                        _buildOperatingHoursSection(),
                      ),

                      const SizedBox(height: 32),

                      // Restaurant Status
                      _buildSettingsSection(
                        'Restaurant Status',
                        Icons.store,
                        _buildRestaurantStatusSection(),
                      ),

                      const SizedBox(height: 32),

                      // Notification Settings
                      _buildSettingsSection(
                        'Notifications',
                        Icons.notifications,
                        _buildNotificationSection(),
                      ),

                      const SizedBox(height: 32),

                      // Security Settings
                      _buildSettingsSection(
                        'Security',
                        Icons.security,
                        _buildSecuritySection(),
                      ),

                      const SizedBox(height: 32),

                      // Account Management
                      _buildSettingsSection(
                        'Account Management',
                        Icons.account_circle,
                        _buildAccountSection(),
                      ),
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
          // Save Button at top for mobile
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Business Information
          _buildSettingsSection(
            'Business Information',
            Icons.business,
            _buildBusinessInfoSection(),
          ),

          const SizedBox(height: 24),

          // Pricing Settings
          _buildSettingsSection(
            'Pricing & Fees',
            Icons.attach_money,
            _buildPricingSection(),
          ),

          const SizedBox(height: 24),

          // Operating Hours
          _buildSettingsSection(
            'Operating Hours',
            Icons.schedule,
            _buildOperatingHoursSection(),
          ),

          const SizedBox(height: 24),

          // Restaurant Status
          _buildSettingsSection(
            'Restaurant Status',
            Icons.store,
            _buildRestaurantStatusSection(),
          ),

          const SizedBox(height: 24),

          // Notification Settings
          _buildSettingsSection(
            'Notifications',
            Icons.notifications,
            _buildNotificationSection(),
          ),

          const SizedBox(height: 24),

          // Security Settings
          _buildSettingsSection(
            'Security',
            Icons.security,
            _buildSecuritySection(),
          ),

          const SizedBox(height: 24),

          // Account Management
          _buildSettingsSection(
            'Account Management',
            Icons.account_circle,
            _buildAccountSection(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, Widget content) {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: content),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      children: [
        _buildTextField('Business Name', _businessNameController, Icons.store),
        const SizedBox(height: 16),
        _buildTextField(
          'Business Email',
          _businessEmailController,
          Icons.email,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Business Phone',
          _businessPhoneController,
          Icons.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Business Address',
          null,
          Icons.location_on,
          hint: 'Enter business address',
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Delivery Fee (Rs.)',
                _deliveryFeeController,
                Icons.delivery_dining,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Tax Rate (%)',
                _taxRateController,
                Icons.percent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Minimum Order Amount (Rs.)',
                _minOrderAmountController,
                Icons.shopping_cart,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Free Delivery Threshold',
                null,
                Icons.local_shipping,
                hint: 'Rs. 1000',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperatingHoursSection() {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            '24/7 Service',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Business operates 24 hours a day',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _isOpen247,
          onChanged: (value) {
            setState(() => _isOpen247 = value);
          },
          activeColor: Colors.orange,
        ),
        if (!_isOpen247) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Opening Time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _openingTime.format(context),
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  onTap: () => _selectTime(true),
                  leading: const Icon(Icons.access_time, color: Colors.orange),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  title: Text(
                    'Closing Time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _closingTime.format(context),
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  onTap: () => _selectTime(false),
                  leading: const Icon(Icons.access_time, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRestaurantStatusSection() {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            'Restaurant Open',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Toggle restaurant availability for orders',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _restaurantStatus,
          onChanged: (value) {
            setState(() => _restaurantStatus = value);
          },
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.red.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _restaurantStatus
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _restaurantStatus ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _restaurantStatus ? Icons.check_circle : Icons.cancel,
                color: _restaurantStatus ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _restaurantStatus
                      ? 'Restaurant is currently OPEN and accepting orders'
                      : 'Restaurant is currently CLOSED and not accepting orders',
                  style: GoogleFonts.poppins(
                    color: _restaurantStatus
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            'Email Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Receive order notifications via email',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _emailNotifications,
          onChanged: (value) {
            setState(() => _emailNotifications = value);
          },
          activeColor: Colors.orange,
        ),
        SwitchListTile(
          title: Text(
            'SMS Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Receive order notifications via SMS',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _smsNotifications,
          onChanged: (value) {
            setState(() => _smsNotifications = value);
          },
          activeColor: Colors.orange,
        ),
        SwitchListTile(
          title: Text(
            'Push Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Receive push notifications on mobile',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
          },
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            'Two-Factor Authentication',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Add an extra layer of security to your account',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _twoFactorAuth,
          onChanged: (value) {
            setState(() => _twoFactorAuth = value);
          },
          activeColor: Colors.orange,
        ),
        SwitchListTile(
          title: Text(
            'Auto Session Timeout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Automatically log out after period of inactivity',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          value: _sessionTimeout,
          onChanged: (value) {
            setState(() => _sessionTimeout = value);
          },
          activeColor: Colors.orange,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _changePassword,
          icon: const Icon(Icons.lock),
          label: const Text('Change Password'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person, color: Colors.orange),
          title: Text(
            'Profile Information',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Update your personal information',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to profile page
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.backup, color: Colors.orange),
          title: Text(
            'Data Backup',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Backup and restore your data',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to backup page
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(
            'Delete Account',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          subtitle: Text(
            'Permanently delete your admin account',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.red,
          ),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController? controller,
    IconData icon, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Admin Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your admin account? This action cannot be undone and will remove all your admin privileges.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await SharedPreferencesHelper.clearAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );

        NavigationHelper.safePush(context, '/login');
      }
    } catch (e) {
      print('❌ Error during account deletion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
