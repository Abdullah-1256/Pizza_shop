import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../domain/entities/user_entity.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loginMethod = 'otp'; // 'password', 'otp', 'google'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Future<bool> onWillPop() async {
    // Handle system back button properly
    return await NavigationHelper.handleBackButton(
      context,
      fallbackRoute: '/product',
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
          onPressed: () => NavigationHelper.handleBackButton(
            context,
            fallbackRoute: '/product',
          ),
        ),
        title: Text(
          "Login",
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pizza,
                      color: Colors.orange,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _loginMethod == 'password'
                      ? 'Enter your email and password to login'
                      : _loginMethod == 'otp'
                      ? 'Enter your email to get a 6-digit login code'
                      : 'Continue with Google to login',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Login Method Selection
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _loginMethod = 'password'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'password'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _loginMethod == 'password'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black12.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Password',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _loginMethod == 'password'
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'otp'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'otp'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _loginMethod == 'otp'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black12.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _loginMethod == 'otp'
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'google'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'google'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _loginMethod == 'google'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black12.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Google',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _loginMethod == 'google'
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  'Email Address',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email, color: Colors.orange),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field (only for password login)
                if (_loginMethod == 'password') ...[
                  Text(
                    'Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                    ),
                    validator: (value) {
                      if (_loginMethod == 'password') {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                ],

                // Login button (different for each method)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loginMethod == 'google'
                          ? Colors.white
                          : Colors.orange,
                      foregroundColor: _loginMethod == 'google'
                          ? Colors.black87
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: _loginMethod == 'google'
                          ? BorderSide(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _loginMethod == 'google'
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_loginMethod == 'google')
                                const Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.red,
                                ),
                              if (_loginMethod == 'google')
                                const SizedBox(width: 8),
                              Text(
                                _loginMethod == 'password'
                                    ? 'Login with Password'
                                    : _loginMethod == 'otp'
                                    ? 'Send OTP Code'
                                    : 'Continue with Google',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_loginMethod == 'password') {
      await _signInWithPassword();
    } else if (_loginMethod == 'otp') {
      await _sendOtp();
    } else if (_loginMethod == 'google') {
      await _signInWithGoogle();
    }
  }

  Future<void> _signInWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('🔐 Signing in with email: $email');

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ Password login successful');

      if (response.user != null && mounted) {
        await _handleSuccessfulLogin(response.user!);
      }
    } on AuthException catch (error) {
      print('❌ Auth Error: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      print('⚠️ Unexpected Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulLogin(User user) async {
    // Check user role and redirect accordingly
    try {
      final profile = await SupabaseService.getUserProfile(user.id);
      final role = profile?['role'] ?? 'customer';

      print('👤 User role: $role');

      // Create UserEntity
      final userEntity = UserEntity.fromSupabaseUser(user);

      // Save user data
      await SharedPreferencesHelper.saveUserData(userEntity);
      await SharedPreferencesHelper.setLoggedIn(true);

      // Redirect based on role
      if (role == 'waiter') {
        NavigationHelper.safeGo(context, '/waiter-dashboard');
      } else if (role == 'admin') {
        NavigationHelper.safeGo(context, '/admin-dashboard');
      } else {
        NavigationHelper.safeGo(context, '/product');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error checking user role: $e');
      // Default to customer flow
      NavigationHelper.safeGo(context, '/product');
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      print('� Sending OTP to: $email');

      // Check if user exists first
      final existingUser = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      final shouldCreateUser = existingUser == null;

      await SupabaseService.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: shouldCreateUser,
      );

      print('✅ OTP request sent successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent successfully! Check your email."),
            backgroundColor: Colors.green,
          ),
        );

        NavigationHelper.safePush(context, '/otp-verification', extra: email);
      }
    } on AuthException catch (error) {
      print('❌ Auth Error: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      print('⚠️ Unexpected Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      // For mobile apps, we need proper redirect URL configuration
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://awrnmnjoedpkyohirekt.supabase.co/auth/v1/callback',
        // Additional mobile-specific options
        queryParams: {'access_type': 'offline', 'prompt': 'consent'},
      );

      // Don't set loading to false here since OAuth will redirect
      // The route callback will handle the rest
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
