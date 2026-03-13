import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/supabase_client.dart';

class ComplaintStatusCheckPage extends StatefulWidget {
  final String? prefilledEmail;

  const ComplaintStatusCheckPage({super.key, this.prefilledEmail});

  @override
  State<ComplaintStatusCheckPage> createState() =>
      _ComplaintStatusCheckPageState();
}

class _ComplaintStatusCheckPageState extends State<ComplaintStatusCheckPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _complaints = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
      // Automatically check status if email is pre-filled
      _checkStatus();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch all complaints for the email
      final response = await SupabaseService.client
          .from('complaints')
          .select()
          .eq('user_email', _emailController.text.trim())
          .order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      if (_complaints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No complaints found for this email address'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'in_review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
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
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          "Check Complaint Status",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Check Your Complaint Status',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email address to view all your complaints and their current status.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Email Field
              Text(
                'Email',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),

              // Check Status Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Check Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Complaints List
              if (_complaints.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Your Complaints',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _complaints[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                          // Status and Tracking Code
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    complaint['status'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatStatusText(complaint['status']),
                                  style: GoogleFonts.poppins(
                                    color: _getStatusColor(complaint['status']),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Tracking: ${complaint['tracking_code'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Subject
                          Text(
                            complaint['subject'] ?? 'No Subject',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Message
                          Text(
                            complaint['message'] ?? 'No message',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date
                          Text(
                            'Submitted: ${_formatDate(complaint['created_at'])}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          // Admin Response
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
                                      fontSize: 14,
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
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
