import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../domain/entities/user_entity.dart';

/// OAuth callback handler for mobile authentication
class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  bool _isProcessing = true;
  String _statusMessage = 'Processing authentication...';

  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    try {
      // Wait a bit for OAuth to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if there's an active session
      final session = SupabaseService.client.auth.currentSession;

      if (session != null && session.user != null) {
        // Create UserEntity from Supabase user
        final userEntity = UserEntity.fromSupabaseUser(session.user!);

        // Check if user has phone number in database
        final dbProfile = await SupabaseService.getUserProfile(userEntity.id);
        final hasPhone =
            dbProfile != null &&
            dbProfile['phone'] != null &&
            dbProfile['phone'].toString().isNotEmpty;

        String? collectedPhoneNumber;

        // If no phone number, show dialog to collect it
        if (!hasPhone && mounted) {
          collectedPhoneNumber = await _showPhoneNumberDialog(userEntity);
        }

        // Create/update user profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: userEntity.id,
          email: userEntity.email ?? '',
          name: userEntity.name,
          phone: collectedPhoneNumber ?? userEntity.phone,
        );

        // Update user entity with collected phone number
        final updatedUserEntity =
            collectedPhoneNumber != null && collectedPhoneNumber!.isNotEmpty
            ? userEntity.copyWith(phone: collectedPhoneNumber)
            : userEntity;

        // Save user data to local storage
        await SharedPreferencesHelper.saveUserData(updatedUserEntity);
        await SharedPreferencesHelper.setLoggedIn(true);
        // Successful authentication
        print('✅ OAuth callback: User authenticated successfully');
        setState(() {
          _statusMessage = 'Authentication successful! Redirecting...';
          _isProcessing = false;
        });

        // Navigate to home page after successful auth
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

        if (mounted) {
          NavigationHelper.safePush(context, '/home');
        }
      } else {
        // No session yet, wait a bit more for OAuth to complete
        print('🔄 OAuth callback: Waiting for authentication to complete...');

        // Wait up to 5 seconds for OAuth to complete
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          final newSession = SupabaseService.client.auth.currentSession;

          if (newSession != null && newSession.user != null) {
            // Create UserEntity from Supabase user
            final userEntity = UserEntity.fromSupabaseUser(newSession.user!);

            // Check if user has phone number in database
            final dbProfile = await SupabaseService.getUserProfile(
              userEntity.id,
            );
            final hasPhone =
                dbProfile != null &&
                dbProfile['phone'] != null &&
                dbProfile['phone'].toString().isNotEmpty;

            String? collectedPhoneNumber;

            // If no phone number, show dialog to collect it
            if (!hasPhone && mounted) {
              collectedPhoneNumber = await _showPhoneNumberDialog(userEntity);
            }

            // Create/update user profile in database
            await SupabaseService.createOrUpdateProfile(
              userId: userEntity.id,
              email: userEntity.email ?? '',
              name: userEntity.name,
              phone: collectedPhoneNumber ?? userEntity.phone,
            );

            // Update user entity with collected phone number
            final updatedUserEntity =
                collectedPhoneNumber != null && collectedPhoneNumber!.isNotEmpty
                ? userEntity.copyWith(phone: collectedPhoneNumber)
                : userEntity;

            // Save user data to local storage
            await SharedPreferencesHelper.saveUserData(updatedUserEntity);
            await SharedPreferencesHelper.setLoggedIn(true);

            print('✅ OAuth callback: Authentication completed successfully');
            setState(() {
              _statusMessage = 'Authentication successful! Redirecting...';
              _isProcessing = false;
            });

            await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

            if (mounted) {
              NavigationHelper.safePush(context, '/home');
            }
            return;
          }
        }

        // Timeout or no session
        print('❌ OAuth callback: Authentication failed or timed out');
        setState(() {
          _statusMessage = 'Authentication failed. Please try again.';
          _isProcessing = false;
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          NavigationHelper.safePush(context, '/login');
        }
      }
    } catch (error) {
      print('❌ OAuth callback error: $error');
      setState(() {
        _statusMessage = 'Authentication error: $error';
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        NavigationHelper.safePush(context, '/login');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 3,
                  )
                else
                  Icon(
                    _statusMessage.contains('successful')
                        ? Icons.check_circle
                        : Icons.error,
                    size: 64,
                    color: _statusMessage.contains('successful')
                        ? Colors.green
                        : Colors.red,
                  ),

                const SizedBox(height: 24),

                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),

                if (!_isProcessing) ...[
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      NavigationHelper.safePush(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
