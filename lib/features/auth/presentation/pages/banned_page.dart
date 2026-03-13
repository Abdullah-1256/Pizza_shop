import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/shared_preferences_helper.dart';

class BannedPage extends StatefulWidget {
  final String? userEmail;

  const BannedPage({super.key, this.userEmail});

  @override
  State<BannedPage> createState() => _BannedPageState();
}

class _BannedPageState extends State<BannedPage> {
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _showComplaintForm = false;

  @override
  void initState() {
    super.initState();
    // Use the email passed from the login flow, or fallback to current user
    final user = Supabase.instance.client.auth.currentUser;
    _emailController.text = widget.userEmail ?? user?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkComplaintStatus() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to complaint status check page with pre-filled email
    context.go('/check-complaint-status', extra: _emailController.text.trim());
  }

  Future<void> _submitComplaint() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both subject and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client.from('complaints').insert({
        'user_id': user.id,
        'user_email': user.email,
        'subject': 'ACCOUNT BAN COMPLAINT: ${_subjectController.text.trim()}',
        'message': _messageController.text.trim(),
        'status': 'pending',
        'type': 'account_ban_complaint',
        'created_at': DateTime.now().toIso8601String(),
        'tracking_code':
            'CMP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      });

      setState(() {
        _showComplaintForm = false;
        _subjectController.clear();
        _messageController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await SharedPreferencesHelper.clearAllData();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Account Restricted',
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: const Icon(Icons.block, color: Colors.red, size: 64),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '🚫 Account Banned',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'Your account has been banned by the administrator. You cannot access the app at this time.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Contact Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.contact_support,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please contact support or file a complaint to appeal this ban.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  // Check Complaint Status Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkComplaintStatus,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        'Check Complaint Status',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // File Complaint Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(
                        () => _showComplaintForm = !_showComplaintForm,
                      ),
                      icon: Icon(
                        _showComplaintForm ? Icons.close : Icons.report_problem,
                        color: Colors.white,
                      ),
                      label: Text(
                        _showComplaintForm
                            ? 'Cancel Complaint'
                            : 'File a Complaint',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Complaint Form
                  if (_showComplaintForm) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File a Complaint',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email (read-only)
                          TextField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Your Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),

                          // Subject
                          TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'Complaint Subject',
                              hintText: 'Brief description of your issue',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),

                          // Message
                          TextField(
                            controller: _messageController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Detailed Complaint',
                              hintText:
                                  'Explain why you believe this ban is unfair...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignLabelWithHint: true,
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitComplaint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
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
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
