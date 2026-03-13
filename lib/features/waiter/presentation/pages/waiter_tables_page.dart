import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';

class WaiterTablesPage extends StatefulWidget {
  const WaiterTablesPage({super.key});

  @override
  State<WaiterTablesPage> createState() => _WaiterTablesPageState();
}

class _WaiterTablesPageState extends State<WaiterTablesPage> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Available', 'Reserved', 'Occupied'];

  List<Map<String, dynamic>> get _filteredTables {
    if (_selectedFilter == 'All') {
      return _tables;
    }
    return _tables
        .where((table) => table['status'] == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final tables = await Supabase.instance.client
          .from('restaurant_tables')
          .select('*')
          .order('table_number');

      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tables: $e');
      setState(() => _isLoading = false);
      // If no tables exist, create some default ones
      await _createDefaultTables();
    }
  }

  Future<void> _createDefaultTables() async {
    try {
      final defaultTables = List.generate(
        12,
        (index) => {
          'table_number': index + 1,
          'seats': 4,
          'status': 'available',
        },
      );

      await Supabase.instance.client
          .from('restaurant_tables')
          .insert(defaultTables);

      // Reload tables after creation
      await _loadTables();
    } catch (e) {
      print('Error creating default tables: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTableStatus(String tableId, String newStatus) async {
    if (newStatus == 'reserved') {
      // Show reservation dialog for reserved tables
      final reservationData = await _showReservationDialog();
      if (reservationData == null) return; // User cancelled

      try {
        // Update table status
        await Supabase.instance.client
            .from('restaurant_tables')
            .update({'status': newStatus})
            .eq('id', tableId);

        // Create reservation record
        await Supabase.instance.client.from('table_reservations').insert({
          'table_id': tableId,
          'customer_name': reservationData['name'],
          'customer_phone': reservationData['phone'],
          'reservation_time': reservationData['time'].toIso8601String(),
        });

        // Reload tables
        await _loadTables();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Table reserved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error creating reservation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create reservation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Regular status update
      try {
        await Supabase.instance.client
            .from('restaurant_tables')
            .update({'status': newStatus})
            .eq('id', tableId);

        // Reload tables
        await _loadTables();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error updating table status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update table status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showReservationDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Reservation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Reservation Time:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedTime),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text(
                      '${selectedTime.day}/${selectedTime.month} ${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'time': selectedTime,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Reserve', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
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
          onPressed: () =>
              NavigationHelper.safeGo(context, '/waiter-dashboard'),
        ),
        title: Text(
          "Table Management",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Restaurant Tables",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Monitor table status and manage reservations",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Text(
                                filter,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                              backgroundColor: Colors.white,
                              selectedColor: filter == 'Available'
                                  ? Colors.green
                                  : filter == 'Reserved'
                                  ? Colors.blue
                                  : filter == 'Occupied'
                                  ? Colors.orange
                                  : Colors.grey,
                              checkmarkColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tables Grid
                    Expanded(
                      child: _tables.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tables found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: _filteredTables.length,
                              itemBuilder: (context, index) {
                                final table = _filteredTables[index];
                                return _buildTableCard(table);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    Color statusColor;
    String statusText;

    switch (table['status']) {
      case 'available':
        statusColor = Colors.green;
        statusText = 'Available';
        break;
      case 'occupied':
        statusColor = Colors.orange;
        statusText = 'Occupied';
        break;
      case 'reserved':
        statusColor = Colors.blue;
        statusText = 'Reserved';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return GestureDetector(
      onTap: () => _showTableDetails(context, table),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Table Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_restaurant, color: statusColor, size: 24),
            ),

            const SizedBox(height: 8),

            // Table Number
            Text(
              'Table ${table['table_number']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 4),

            // Capacity
            Text(
              '${table['seats']} seats',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
            ),

            const SizedBox(height: 4),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTableDetails(BuildContext context, Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Table ${table['table_number']} Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacity: ${table['seats']} seats',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${table['status'].toString().toUpperCase()}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            // Status change buttons
            Text(
              'Change Status:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (table['status'] != 'available')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateTableStatus(table['id'], 'available');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Available',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                if (table['status'] != 'available') const SizedBox(width: 8),
                if (table['status'] != 'occupied')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateTableStatus(table['id'], 'occupied');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Occupied',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                if (table['status'] != 'occupied') const SizedBox(width: 8),
                if (table['status'] != 'reserved')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateTableStatus(table['id'], 'reserved');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Reserved',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
          if (table['status'] == 'available')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to take order for this table
                NavigationHelper.safePush(context, '/waiter-take-order');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Take Order', style: GoogleFonts.poppins()),
            ),
        ],
      ),
    );
  }
}
