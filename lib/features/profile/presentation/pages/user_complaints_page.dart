import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/utils/shared_preferences_helper.dart';

class UserComplaintsPage extends StatefulWidget {
  const UserComplaintsPage({super.key});

  @override
  State<UserComplaintsPage> createState() => _UserComplaintsPageState();
}

class _UserComplaintsPageState extends State<UserComplaintsPage> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  RealtimeChannel? _complaintsSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserComplaints();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _complaintsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUserComplaints() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final complaints = await SupabaseService.getUserComplaints(user.id);

      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading user complaints: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Use the helper method for user-specific complaints subscription
    _complaintsSubscription = RealtimeService.createUserComplaintsSubscription(
      user.id,
      (payload) {
        print(
          '🔔 User complaint update received: ${payload.eventType} -> ${payload.newRecord?['id']}',
        );
        // Refresh complaints list when any change occurs
        _loadUserComplaints();
      },
    ).subscribe();
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
          "My Complaints",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            onPressed: () => _showSubmitComplaintDialog(context),
            tooltip: 'Submit New Complaint',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _complaints.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height - kToolbarHeight - 100,
                child: _buildEmptyState(),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserComplaints,
              color: Colors.orange,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: _complaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(_complaints[index]);
                },
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
              Icons.feedback_outlined,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No complaints yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first complaint to get help',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSubmitComplaintDialog(context),
            icon: const Icon(Icons.add),
            label: Text(
              'Submit Complaint',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                    _formatComplaintType(complaint['type']),
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
                  formattedDate,
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Complaint Details
                Container(
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
                      Text(
                        complaint['message'] ?? 'No message provided',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      if (complaint['order_id'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Related Order: #${complaint['order_id']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Admin Response
                if (complaint['admin_response'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                ] else if (complaint['status'] == 'pending') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Waiting for admin response...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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

  void _showSubmitComplaintDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => const ComplaintSubmissionForm(),
    );
  }
}

class ComplaintSubmissionForm extends StatefulWidget {
  const ComplaintSubmissionForm({super.key});

  @override
  State<ComplaintSubmissionForm> createState() =>
      _ComplaintSubmissionFormState();
}

class _ComplaintSubmissionFormState extends State<ComplaintSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'order_issue';
  String? _selectedOrderId;
  bool _isSubmitting = false;

  final List<Map<String, String>> _complaintTypes = [
    {'value': 'order_issue', 'label': 'Order Issue'},
    {'value': 'food_quality', 'label': 'Food Quality'},
    {'value': 'delivery_delay', 'label': 'Delivery Delay'},
    {'value': 'wrong_order', 'label': 'Wrong Order'},
    {'value': 'payment_issue', 'label': 'Payment Issue'},
    {'value': 'app_issue', 'label': 'App Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Submit a Complaint',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Complaint Type
                Text(
                  'Complaint Type',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _complaintTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(
                        type['label']!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Subject
                Text(
                  'Subject',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Brief description of the issue',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'Message',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Please provide detailed information about your complaint',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Complaint',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20), // Extra space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to submit a complaint'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get user profile for email
      final userProfile = await SharedPreferencesHelper.getUserProfile();

      final complaintData = {
        'user_id': user.id,
        'user_email': userProfile?['email'] ?? user.email ?? 'Unknown',
        'type': _selectedType,
        'subject': _subjectController.text.trim(),
        'message': _descriptionController.text.trim(),
        'status': 'pending',
        'order_id': _selectedOrderId,
      };

      await Supabase.instance.client.from('complaints').insert(complaintData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the complaints list
        if (context.mounted) {
          context
              .findAncestorStateOfType<_UserComplaintsPageState>()
              ?._loadUserComplaints();
        }
      }
    } catch (e) {
      print('Error submitting complaint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit complaint. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
