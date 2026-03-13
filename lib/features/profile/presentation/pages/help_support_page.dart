import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/shared_preferences_helper.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
          "Help & Support",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'How can we help you?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickAction(
              icon: Icons.chat,
              title: 'Chat with Support',
              subtitle: 'Get instant help from our team',
              onTap: () => _showChatSupport(context),
            ),

            _buildQuickAction(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+92 300 123 4567',
              onTap: () => _showCallDialog(context),
            ),

            _buildQuickAction(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@pizzatime.com',
              onTap: () => _showEmailDialog(context),
            ),

            const SizedBox(height: 30),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _buildFAQItem(
              question: 'How do I place an order?',
              answer:
                  'Browse our menu, add items to cart, and proceed to checkout. You can pay online or choose cash on delivery.',
            ),

            _buildFAQItem(
              question: 'What are your delivery hours?',
              answer:
                  'We deliver from 11:00 AM to 11:00 PM daily. Delivery times may vary based on location and order volume.',
            ),

            _buildFAQItem(
              question: 'How can I track my order?',
              answer:
                  'You will receive SMS updates about your order status. You can also check your order history in the app.',
            ),

            _buildFAQItem(
              question: 'What is your refund policy?',
              answer:
                  'We offer full refunds for orders that arrive late, cold, or incorrect. Contact support within 24 hours of delivery.',
            ),

            _buildFAQItem(
              question: 'Do you offer vegetarian options?',
              answer:
                  'Yes! We have a wide variety of vegetarian pizzas, pastas, and sides. Look for the green leaf icon on our menu.',
            ),

            const SizedBox(height: 30),

            // Contact Information
            Container(
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
                    'Contact Information',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: '+92 300 123 4567',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.email,
                    title: 'Email',
                    value: 'support@pizzatime.com',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.location_on,
                    title: 'Address',
                    value: '123 Pizza Street, Lahore, Pakistan',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.access_time,
                    title: 'Support Hours',
                    value: 'Mon-Sun: 10:00 AM - 10:00 PM',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Report Issue Button
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReportIssueDialog(context),
                icon: const Icon(Icons.report_problem, color: Colors.red),
                label: Text(
                  'Report an Issue',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orange, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black38,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
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
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChatSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chat Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Our support team is available 24/7. Start a chat now?',
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open chat support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat support will be available soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Start Chat', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Call Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Call our support team at +92 300 123 4567?',
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Initiate phone call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling support...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Call Now', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Email Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Send an email to support@pizzatime.com?',
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open email client
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Send Email', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
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
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
          ],
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
