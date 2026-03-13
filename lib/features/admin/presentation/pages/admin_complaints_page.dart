import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../widgets/admin_sidebar.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _searchQuery = '';
  RealtimeChannel? _complaintsSubscription;

  final List<String> _statusOptions = [
    'All',
    'pending',
    'in_review',
    'resolved',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _complaintsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    try {
      setState(() => _isLoading = true);

      final complaints = await SupabaseService.getComplaints();

      setState(() {
        _complaints = complaints;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading complaints: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    _complaintsSubscription = Supabase.instance.client
        .channel('admin_complaints')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            print('🔔 Complaint update received: ${payload.eventType}');
            _loadComplaints();
          },
        )
        .subscribe();
  }

  void _applyFilters() {
    setState(() {
      _filteredComplaints = _complaints.where((complaint) {
        final statusMatch =
            _selectedStatus == 'All' || complaint['status'] == _selectedStatus;

        final searchMatch =
            _searchQuery.isEmpty ||
            (complaint['user_email']?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (complaint['subject']?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (complaint['id'].toString().contains(_searchQuery));

        return statusMatch && searchMatch;
      }).toList();
    });
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
              child: const AdminSidebar(currentRoute: '/admin-complaints'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "📞 Complaints",
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
                  onPressed: _loadComplaints,
                  tooltip: 'Refresh Complaints',
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
        const AdminSidebar(currentRoute: '/admin-complaints'),
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
                      "📞 Complaints Management",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: _loadComplaints,
                      tooltip: 'Refresh Complaints',
                    ),
                  ],
                ),
              ),

              // Filters and Search
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    // Status Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_formatStatusText(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search by ID, Email or Subject',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Complaints List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : _filteredComplaints.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadComplaints,
                        color: Colors.orange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredComplaints.length,
                          itemBuilder: (context, index) {
                            return _buildComplaintCard(
                              _filteredComplaints[index],
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
        // Filters and Search - responsive layout
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Status Filter
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_formatStatusText(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search by ID, Email or Subject',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
              ),
            ],
          ),
        ),

        // Complaints List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _filteredComplaints.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadComplaints,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredComplaints.length,
                    itemBuilder: (context, index) {
                      return _buildComplaintCard(_filteredComplaints[index]);
                    },
                  ),
                ),
        ),
      ],
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
              Icons.feedback_outlined,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No complaints found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    Color statusColor;
    switch (complaint['status']) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      case 'in_review':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    final createdAt = DateTime.parse(complaint['created_at']);
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.feedback, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint['subject'] ?? 'No Subject',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    complaint['user_email'] ?? 'Unknown User',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatusText(complaint['status']),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatComplaintType(complaint['type']),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formattedDate,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Complaint Details
                _buildComplaintDetails(complaint),

                const SizedBox(height: 16),

                // Admin Response Section
                Text(
                  'Admin Response',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAdminResponseSection(complaint),

                const SizedBox(height: 16),

                // Status Update Section
                Text(
                  'Update Complaint Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusUpdateButtons(complaint),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintDetails(Map<String, dynamic> complaint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Type',
                  _formatComplaintType(complaint['type']),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Status',
                  _formatStatusText(complaint['status']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailItem(
            'Message',
            complaint['message'] ?? 'No message provided',
          ),
          if (complaint['order_id'] != null) ...[
            const SizedBox(height: 8),
            _buildDetailItem(
              'Related Order',
              'Order #${complaint['order_id']}',
            ),
          ],
          if (complaint['admin_response'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Response',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint['admin_response'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminResponseSection(Map<String, dynamic> complaint) {
    final TextEditingController responseController = TextEditingController(
      text: complaint['admin_response'] ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reply to Customer',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: responseController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your response to the customer...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveAdminResponse(
                    complaint['id'],
                    responseController.text.trim(),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(
                    complaint['admin_response'] != null
                        ? 'Update Response'
                        : 'Send Response',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (complaint['admin_response'] != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _saveAdminResponse(complaint['id'], ''),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Response',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButtons(Map<String, dynamic> complaint) {
    final currentIndex = _statusOptions.indexOf(complaint['status']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.skip(1).map((status) {
        final statusIndex = _statusOptions.indexOf(status);
        final isCurrent = statusIndex == currentIndex;
        final isCompleted = statusIndex < currentIndex;

        return ElevatedButton(
          onPressed: isCurrent
              ? null
              : () => _updateComplaintStatus(complaint['id'], status),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrent
                ? Colors.grey
                : isCompleted
                ? Colors.green
                : Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            _formatStatusText(status),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_review':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status.toUpperCase();
    }
  }

  String _formatComplaintType(String type) {
    switch (type) {
      case 'order_issue':
        return 'Order Issue';
      case 'food_quality':
        return 'Food Quality';
      case 'delivery_delay':
        return 'Delivery Delay';
      case 'wrong_order':
        return 'Wrong Order';
      case 'payment_issue':
        return 'Payment Issue';
      case 'app_issue':
        return 'App Issue';
      case 'other':
        return 'Other';
      default:
        return type.toUpperCase();
    }
  }

  Future<void> _updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    try {
      final updateData = {'status': newStatus};

      if (newStatus == 'resolved' || newStatus == 'closed') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      await SupabaseService.updateComplaint(complaintId, updateData);

      await _loadComplaints();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Complaint status updated to ${_formatStatusText(newStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating complaint status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update complaint status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAdminResponse(String complaintId, String response) async {
    try {
      final updateData = {
        'admin_response': response.isEmpty ? null : response,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.updateComplaint(complaintId, updateData);

      await _loadComplaints();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.isEmpty
                  ? 'Admin response removed'
                  : 'Admin response ${response.isEmpty ? 'removed' : 'saved'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving admin response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save admin response'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
