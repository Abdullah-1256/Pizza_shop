import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/supabase_client.dart';

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({super.key});

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final String label;
  bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postalCode,
    required this.label,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress =>
      '$addressLine1${addressLine2.isNotEmpty ? '\n$addressLine2' : ''}\n$city, $postalCode';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'label': label,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      addressLine1: json['address_line1'] as String,
      addressLine2: json['address_line2'] as String? ?? '',
      city: json['city'] as String,
      postalCode: json['postal_code'] as String,
      label: json['label'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory Address.create({
    required String userId,
    required String fullName,
    required String phone,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String postalCode,
    required String label,
    bool isDefault = false,
  }) {
    return Address(
      id: '', // Will be set by database
      userId: userId,
      fullName: fullName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      postalCode: postalCode,
      label: label,
      isDefault: isDefault,
    );
  }
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  final List<Address> _addresses = [];
  bool _isLoading = true;
  String? _editingAddressId;

  bool _isAddingNew = false;
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final response = await SupabaseService.client
        .from('delivery_addresses')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    setState(() {
      _addresses.clear();
      _addresses.addAll(
        response.map<Address>((e) => Address.fromJson(e)).toList(),
      );
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
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
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          "Delivery Addresses",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _isAddingNew = true),
          ),
        ],
      ),
      body: _isAddingNew ? _buildAddAddressForm() : _buildAddressList(),
    );
  }

  Widget _buildAddressList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Your Addresses',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your delivery addresses',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // Address List
          ..._addresses.map((address) => _buildAddressCard(address)),

          const SizedBox(height: 20),

          // Add New Address Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isAddingNew = true),
              icon: const Icon(Icons.add, color: Colors.orange),
              label: Text(
                'Add New Address',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can add multiple addresses and set one as default. During checkout, you can select from saved addresses or add a new one.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? Colors.orange : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address.label == 'Home' ? Icons.home : Icons.business,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.addressLine1,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.addressLine2.isNotEmpty) ...[
                    Text(
                      address.addressLine2,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Text(
                    address.city,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleAddressAction(address, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'set_default',
                  child: Text('Set as Default'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isAddingNew = false),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add New Address',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Address Label
            Text(
              'Address Label',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g. Home, Office, Friend\'s Place',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address label';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Full Name
            Text(
              'Full Name',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter full name for delivery',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phone Number
            Text(
              'Phone Number',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '+92 300 1234567',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Address Line 1
            Text(
              'Address Line 1',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressLine1Controller,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Street address, building, apartment',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address line 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Address Line 2 (Optional)
            Text(
              'Address Line 2 (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Floor, landmark, or additional details',
              ),
            ),
            const SizedBox(height: 20),

            // City Field
            Text(
              'City',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter city name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter city';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Address Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                    'Address Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPreviewAddress(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNewAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Address',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewAddress() {
    final addressLine1 = _addressLine1Controller.text;
    final addressLine2 = _addressLine2Controller.text;
    final city = _cityController.text;

    if (addressLine1.isEmpty && city.isEmpty) {
      return 'Address preview will appear here';
    }

    return '$addressLine1${addressLine2.isNotEmpty ? '\n$addressLine2' : ''}\n$city';
  }

  void _handleAddressAction(Address address, String action) {
    switch (action) {
      case 'edit':
        _editAddress(address);
        break;
      case 'set_default':
        _setAsDefault(address);
        break;
      case 'delete':
        _deleteAddress(address);
        break;
    }
  }

  void _editAddress(Address address) {
    _labelController.text = address.label;
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phone;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2;
    _cityController.text = address.city;
    // No postal code field anymore
    setState(() => _isAddingNew = true);
  }

  void _setAsDefault(Address address) async {
    final payload = {'is_default': true};

    await SupabaseService.client
        .from('delivery_addresses')
        .update(payload)
        .eq('id', address.id);

    await _loadAddresses();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${address.label} set as default address')),
    );
  }

  void _deleteAddress(Address address) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.client
                  .from('delivery_addresses')
                  .delete()
                  .eq('id', address.id);

              await _loadAddresses();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _saveNewAddress() async {
    if (_formKey.currentState!.validate()) {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final addressData = {
        'user_id': currentUser.id,
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': '', // Not using postal code anymore
        'label': _labelController.text.trim(),
        'is_default': false,
      };

      await SupabaseService.client
          .from('delivery_addresses')
          .insert(addressData);

      await _loadAddresses();
      setState(() {
        _isAddingNew = false;
        _clearForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully!')),
      );
    }
  }

  void _clearForm() {
    _labelController.clear();
    _fullNameController.clear();
    _phoneController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
  }
}
