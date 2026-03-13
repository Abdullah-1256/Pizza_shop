import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../domain/entities/user_entity.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
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
          "Verify Email",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email, color: Colors.orange, size: 48),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                'Check your email',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We\'ve sent a 6-digit verification code to',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // OTP Input
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onCompleted: (pin) => _verifyOtp(pin),
              ),
              const SizedBox(height: 30),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _verifyOtp(_otpController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                          'Verify & Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend Code
              TextButton(
                onPressed: _canResend ? _resendOtp : null,
                child: Text(
                  _canResend
                      ? 'Resend Code'
                      : 'Resend code in ${_resendTimer}s',
                  style: GoogleFonts.poppins(
                    color: _canResend ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Wrong Email?
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Wrong email? Change it',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your spam/junk folder if you don\'t see the email in your inbox.',
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
        ),
      ),
    );
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 Verifying OTP: $otp for email: ${widget.email}');

      final response = await SupabaseService.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      print('✅ OTP verification response received');
      print('Session: ${response.session != null ? 'Present' : 'Null'}');
      print('User: ${response.user != null ? 'Present' : 'Null'}');

      if (response.user != null && mounted) {
        print('✅ OTP verification successful - user found');

        // Check if user is banned before proceeding
        try {
          final userData = await SupabaseService.client
              .from('users')
              .select('is_banned')
              .eq('id', response.user!.id)
              .maybeSingle();

          final isBanned = userData?['is_banned'] as bool? ?? false;

          if (isBanned) {
            print(
              '🚫 User is banned - denying login and redirecting to banned screen',
            );
            if (mounted) {
              // Store the email before signing out so banned page can use it
              final bannedUserEmail = widget.email;

              // Sign out the user to prevent access to other screens
              try {
                await SupabaseService.client.auth.signOut();
                await SharedPreferencesHelper.clearAllData();
              } catch (e) {
                print('Error signing out banned user: $e');
              }

              // Navigate directly to banned screen with email
              NavigationHelper.safeGo(
                context,
                '/banned',
                extra: bannedUserEmail,
              );
            }
            return;
          }
        } catch (banCheckError) {
          print(
            '⚠️ Could not check ban status, proceeding with login: $banCheckError',
          );
          // If we can't check ban status, allow login for safety
        }

        // Create UserEntity from Supabase user
        final userEntity = UserEntity.fromSupabaseUser(response.user!);

        // Show phone number dialog for new users
        String? collectedPhoneNumber;
        if (mounted) {
          collectedPhoneNumber = await _showPhoneNumberDialog(userEntity);
        }

        // Print the complete response for debugging
        print('🔥 OTP VERIFICATION SUCCESS RESPONSE:');
        print('User ID: ${response.user!.id}');
        print('Email: ${response.user!.email}');
        print('Email Confirmed: ${response.user!.emailConfirmedAt}');
        print('Created At: ${response.user!.createdAt}');
        print('Last Sign In: ${response.user!.lastSignInAt}');
        print('User Metadata: ${response.user!.userMetadata}');
        print('App Metadata: ${response.user!.appMetadata}');
        print('Phone: ${response.user!.phone}');
        print('Role: ${response.user!.role}');
        print('Aud: ${response.user!.aud}');
        print('Is Anonymous: ${response.user!.isAnonymous}');
        print('Full User Entity: ${userEntity.toJson()}');

        // Create/update user profile in database
        try {
          await SupabaseService.createOrUpdateProfile(
            userId: userEntity.id,
            email: userEntity.email ?? widget.email,
            name: userEntity.name,
            phone: collectedPhoneNumber ?? userEntity.phone,
          );
          print('✅ User profile created/updated successfully');
        } catch (profileError) {
          print(
            '⚠️ Profile creation failed, but continuing with login: $profileError',
          );
          // Don't fail the entire login if profile creation fails
        }

        // Update user entity with collected phone number
        final updatedUserEntity =
            collectedPhoneNumber != null && collectedPhoneNumber!.isNotEmpty
            ? userEntity.copyWith(phone: collectedPhoneNumber)
            : userEntity;

        // Save user data to local storage
        await SharedPreferencesHelper.saveUserData(updatedUserEntity);
        await SharedPreferencesHelper.setLoggedIn(true);

        // Successfully authenticated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check user role and redirect accordingly
        try {
          final profile = await SupabaseService.getUserProfile(
            response.user!.id,
          );
          final role = profile?['role'] ?? 'customer';

          print('👤 User role: $role');

          // Save role-based status for future app launches
          if (role == 'admin') {
            await SharedPreferencesHelper.setAdminStatus(true);
            await SharedPreferencesHelper.saveAdminToken(response.user!.id);
          }

          // Redirect based on role
          if (role == 'waiter') {
            print('🍽️ WAITER USER - Navigating to waiter dashboard');
            if (mounted) {
              NavigationHelper.safeGo(context, '/waiter-dashboard');
            }
          } else if (role == 'admin') {
            print('👑 ADMIN USER - Navigating to admin dashboard');
            if (mounted) {
              NavigationHelper.safeGo(context, '/admin-dashboard');
            }
          } else {
            print('👤 CUSTOMER USER - Navigating to product page');
            if (mounted) {
              NavigationHelper.safeGo(context, '/product');
            }
          }
        } catch (roleError) {
          print('❌ Role check failed: $roleError');
          // Default to customer flow
          if (mounted) {
            NavigationHelper.safeGo(context, '/product');
          }
        }
      }
    } on AuthException catch (error) {
      print('❌ AuthException during OTP verification: ${error.message}');
      print('Error status code: ${error.statusCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      print('❌ Unexpected error during OTP verification: $error');
      print('Error type: ${error.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showPhoneNumberDialog(UserEntity userEntity) async {
    final phoneController = TextEditingController();
    String? phoneNumber;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                '📱 Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Please provide your phone number to complete your profile and receive order updates.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Phone Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+92 300 1234567',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Info Text
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This helps us contact you about your orders',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // Skip Button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Skip for Now',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        phoneNumber = phoneController.text.trim();
                        if (phoneNumber!.isNotEmpty) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.orange.withOpacity(0.3),
                      ),
                      child: Text(
                        'Save & Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

    return phoneNumber;
  }

  Future<void> _showContactSupportDialog() async {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Contact Admin Support',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Send a message to the administrator regarding your account ban.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Show user's email
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'From: ${widget.email}',
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
              const SizedBox(height: 24),

              // Subject Field
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of your issue',
                  labelStyle: GoogleFonts.poppins(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.subject, color: Colors.blue),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),

              // Message Field
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText:
                      'Explain your situation and why you think the ban should be lifted...',
                  labelStyle: GoogleFonts.poppins(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (subjectController.text.trim().isEmpty ||
                            messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill in both subject and message',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Create support message complaint
                          final response = await SupabaseService.addComplaint({
                            'user_id': SupabaseService.currentUser?.id,
                            'user_email': widget.email,
                            'subject':
                                'ACCOUNT BAN SUPPORT: ${subjectController.text.trim()}',
                            'message': messageController.text.trim(),
                            'status': 'pending',
                            'type': 'account_ban_support',
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          final trackingCode =
                              response['tracking_code'] ?? 'N/A';

                          Navigator.pop(context);

                          // Show tracking code dialog
                          if (mounted) {
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Complaint Submitted'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Your support request has been submitted successfully!',
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Tracking Code: $trackingCode',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Save this code to check your complaint status later.',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error sending support message: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to send support message. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Send Message',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Future<void> _showFileComplaintDialog() async {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'File a Complaint',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Report inappropriate behavior or unfair banning.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Show user's email
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'From: ${widget.email}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subject Field
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Complaint Subject',
                  hintText: 'What happened?',
                  labelStyle: GoogleFonts.poppins(color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.report, color: Colors.orange),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),

              // Message Field
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Detailed Complaint',
                  hintText:
                      'Please describe what happened and why you believe this ban is unfair...',
                  labelStyle: GoogleFonts.poppins(color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (subjectController.text.trim().isEmpty ||
                            messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill in both subject and complaint details',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Create complaint
                          final response = await SupabaseService.addComplaint({
                            'user_id': SupabaseService.currentUser?.id,
                            'user_email': widget.email,
                            'subject':
                                'ACCOUNT BAN COMPLAINT: ${subjectController.text.trim()}',
                            'message': messageController.text.trim(),
                            'status': 'pending',
                            'type': 'account_ban_complaint',
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          final trackingCode =
                              response['tracking_code'] ?? 'N/A';

                          Navigator.pop(context);

                          // Show tracking code dialog
                          if (mounted) {
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Complaint Filed'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Your complaint has been filed successfully!',
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Tracking Code: $trackingCode',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Save this code to check your complaint status later.',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error filing complaint: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to file complaint. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'File Complaint',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Future<void> _resendOtp() async {
    try {
      await SupabaseService.client.auth.signInWithOtp(email: widget.email);

      setState(() {
        _canResend = false;
        _resendTimer = 30;
      });

      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBannedUserDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap OK to dismiss
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: const Icon(Icons.block, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '🚫 Account Banned',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.contact_support,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please contact support for more information.',
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
              const SizedBox(height: 24),

              // Action Buttons
              Column(
                children: [
                  // Contact Support Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Close current dialog
                        Navigator.pop(context);

                        // Show contact support dialog
                        await _showContactSupportDialog();
                      },
                      icon: const Icon(
                        Icons.contact_support,
                        color: Colors.blue,
                      ),
                      label: Text(
                        'Contact Admin Support',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // File Complaint Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Close current dialog
                        Navigator.pop(context);

                        // Show file complaint dialog
                        await _showFileComplaintDialog();
                      },
                      icon: const Icon(
                        Icons.report_problem,
                        color: Colors.orange,
                      ),
                      label: Text(
                        'File a Complaint',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Check Complaint Status Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Close current dialog
                        Navigator.pop(context);

                        // Navigate to complaint status check page
                        context.go('/check-complaint-status');
                      },
                      icon: const Icon(Icons.search, color: Colors.blue),
                      label: Text(
                        'Check Complaint Status',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OK Button (Logout)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Close dialog
                        Navigator.pop(context);

                        // Logout user
                        try {
                          await SupabaseService.client.auth.signOut();
                          await SharedPreferencesHelper.clearAllData();

                          // Navigate to login page
                          if (mounted) {
                            NavigationHelper.safePush(context, '/login');
                          }
                        } catch (e) {
                          print('Error during logout: $e');
                          // Still navigate to login even if logout fails
                          if (mounted) {
                            NavigationHelper.safePush(context, '/login');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.red.withOpacity(0.3),
                      ),
                      child: Text(
                        'OK - Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
