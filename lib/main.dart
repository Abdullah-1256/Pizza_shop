import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'CartPage.dart';
import 'FavoritePage.dart';
import 'HomePage.dart';
import 'PizzaOrderScreen.dart';
import 'ProfilePage.dart';
import 'core/constants/app_constants.dart';
import 'features/menu/presentation/pages/product_detail_page.dart';
import 'features/profile/presentation/pages/personal_information_page.dart';
import 'features/profile/presentation/pages/delivery_address_page.dart';
import 'features/profile/presentation/pages/payment_methods_page.dart';
import 'features/profile/presentation/pages/order_history_page.dart';
import 'features/admin/presentation/pages/admin_dashboard.dart';
import 'features/admin/presentation/pages/admin_orders_page.dart';
import 'features/admin/presentation/pages/admin_analytics_page.dart';
import 'features/admin/presentation/pages/admin_complaints_page.dart';
import 'features/admin/presentation/pages/admin_menu_page.dart';
import 'features/admin/presentation/pages/admin_customers_page.dart';
import 'features/admin/presentation/pages/admin_reports_page.dart';
import 'features/admin/presentation/pages/admin_delivery_page.dart';
import 'features/admin/presentation/pages/admin_settings_page.dart';
import 'features/profile/presentation/pages/notifications_page.dart';
import 'features/profile/presentation/pages/help_support_page.dart';
import 'features/profile/presentation/pages/user_complaints_page.dart';
import 'features/profile/presentation/pages/about_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/waiter/presentation/pages/waiter_dashboard.dart';
import 'features/waiter/presentation/pages/waiter_take_order_page.dart';
import 'features/waiter/presentation/pages/waiter_orders_page.dart';
import 'features/waiter/presentation/pages/waiter_tables_page.dart';
import 'features/waiter/presentation/pages/waiter_bills_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/oauth_callback_page.dart';
import 'features/auth/presentation/pages/complaint_status_check_page.dart';
import 'features/auth/presentation/pages/banned_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/order_tracking/presentation/pages/order_tracking_page.dart';
import 'core/utils/shared_preferences_helper.dart';
import 'core/network/supabase_client.dart';
import 'core/services/realtime_service.dart';

GoRouter _buildWaiterRouter() {
  return GoRouter(
    initialLocation: '/waiter-dashboard',
    routes: [
      GoRoute(
        path: '/waiter-dashboard',
        builder: (context, state) => const WaiterDashboard(),
      ),
      GoRoute(
        path: '/waiter-take-order',
        builder: (context, state) => const WaiterTakeOrderPage(),
      ),
      GoRoute(
        path: '/waiter-orders',
        builder: (context, state) => const WaiterOrdersPage(),
      ),
      GoRoute(
        path: '/waiter-tables',
        builder: (context, state) => const WaiterTablesPage(),
      ),
      GoRoute(
        path: '/waiter-bills',
        builder: (context, state) => const WaiterBillsPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Realtime service
  await RealtimeService.init();

  // For testing waiter panel - run with simple router
  runApp(
    MaterialApp.router(
      title: 'Waiter Panel',
      debugShowCheckedModeBanner: false,
      routerConfig: _buildWaiterRouter(),
    ),
  );

  /*
  // Check if user is already logged in
  final isLoggedIn = await SharedPreferencesHelper.isLoggedIn();
  print('🔐 App start - User login status: $isLoggedIn');

  runApp(MyApp(isLoggedIn: isLoggedIn));
  */
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _initialLocation = '/splash';
  bool _locationDetermined = false;

  @override
  void initState() {
    super.initState();
    _determineInitialLocation();
  }

  Future<void> _determineInitialLocation() async {
    if (!widget.isLoggedIn) {
      setState(() {
        _initialLocation = '/splash';
        _locationDetermined = true;
      });
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        print('🔍 Checking admin status for user: ${user.email}');

        // First, check if we have stored admin status
        bool isAdmin = await SharedPreferencesHelper.isAdmin();
        print('💾 Stored admin status: $isAdmin');

        // If no stored admin status, check with RPC
        if (!isAdmin) {
          print('👤 User email: ${user.email}');
          print('🆔 User ID: ${user.id}');

          try {
            final adminCheck = await Supabase.instance.client.rpc('is_admin');
            print('📡 RPC raw response: $adminCheck');
            print('📡 RPC response type: ${adminCheck.runtimeType}');

            if (adminCheck is bool) {
              isAdmin = adminCheck;
            } else {
              isAdmin = false;
              print('⚠️ RPC returned non-boolean value');
            }
            print('✅ RPC function worked: isAdmin = $isAdmin');

            // Save admin status for future use
            if (isAdmin) {
              await SharedPreferencesHelper.setAdminStatus(true);
              await SharedPreferencesHelper.saveAdminToken(
                user.id,
              ); // Save user ID as admin token
              print('💾 Admin status saved to local storage');
            }
          } catch (rpcError) {
            print('⚠️ RPC function failed: $rpcError');
            print('🔄 Using profiles table fallback check');

            // Fallback: check profiles table for admin role
            try {
              final profile = await SupabaseService.getUserProfile(user.id);
              isAdmin = profile?['role'] == 'admin';
              print(
                '👤 Profile role check: ${profile?['role']} == "admin" = $isAdmin',
              );
            } catch (profileError) {
              print('⚠️ Profile check failed: $profileError');
              // Last resort: check if email is admin email
              isAdmin = user.email == 'abdullahmubashar280@gmail.com';
              print(
                '📧 Email comparison: "${user.email}" == "abdullahmubashar280@gmail.com" = $isAdmin',
              );
            }

            // Save admin status for future use
            if (isAdmin) {
              await SharedPreferencesHelper.setAdminStatus(true);
              await SharedPreferencesHelper.saveAdminToken(user.id);
              print('💾 Admin status saved to local storage (fallback)');
            }
          }
        } else {
          print('✅ Using stored admin status - no RPC call needed');
        }

        print('🎯 FINAL ADMIN DECISION: $isAdmin');

        // Check if user is banned
        bool isBanned = false;
        try {
          final userData = await Supabase.instance.client
              .from('users')
              .select('is_banned')
              .eq('id', user.id)
              .maybeSingle();

          isBanned = userData?['is_banned'] as bool? ?? false;
          print('🚫 User ban status: $isBanned');
        } catch (banCheckError) {
          print('⚠️ Could not check ban status: $banCheckError');
          // If we can't check ban status, allow access for safety
          isBanned = false;
        }

        if (isBanned) {
          print('🚫 BANNED USER - Redirecting to banned screen');
          setState(() {
            _initialLocation = '/banned';
            _locationDetermined = true;
          });
        } else {
          setState(() {
            _initialLocation = isAdmin ? '/admin-dashboard' : '/product';
            _locationDetermined = true;
          });
        }

        print('🎯 Final routing decision: $_initialLocation');
      } else {
        print('❌ No authenticated user found');
        setState(() {
          _initialLocation = '/product';
          _locationDetermined = true;
        });
      }
    } catch (e) {
      print('❌ Error checking admin status: $e');
      print('❌ Error details: ${e.toString()}');
      setState(() {
        _initialLocation = '/product';
        _locationDetermined = true;
      });
    }
  }

  Future<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;

    // Allow access to public routes
    final publicRoutes = [
      '/splash',
      '/login',
      '/auth/callback',
      '/auth/v1/callback',
      '/',
      '/check-complaint-status',
      '/otp-verification',
      '/banned',
    ];
    if (publicRoutes.contains(state.matchedLocation)) {
      return null;
    }

    // If not logged in, redirect to login
    if (user == null) {
      return '/login';
    }

    // Check if user is banned
    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('is_banned')
          .eq('id', user.id)
          .maybeSingle();

      final isBanned = userData?['is_banned'] as bool? ?? false;

      if (isBanned && state.matchedLocation != '/banned') {
        return '/banned';
      }
    } catch (e) {
      print('Error checking ban status in redirect: $e');
      // If we can't check, allow access for safety
    }

    return null;
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: _initialLocation,
      redirect: _handleRedirect,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/product',
          builder: (context, state) => const ProductsPage(),
        ),
        GoRoute(
          path: '/favorite',
          builder: (context, state) => const FavoritePage(),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
        GoRoute(
          path: '/order',
          builder: (context, state) => const PizzaOrderScreen(),
        ),
        GoRoute(
          path: '/personal-info',
          builder: (context, state) => const PersonalInformationPage(),
        ),
        GoRoute(
          path: '/delivery-address',
          builder: (context, state) => const DeliveryAddressPage(),
        ),
        GoRoute(
          path: '/payment-methods',
          builder: (context, state) => const PaymentMethodsPage(),
        ),
        GoRoute(
          path: '/order-history',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin-orders',
          builder: (context, state) => const AdminOrdersPage(),
        ),
        GoRoute(
          path: '/admin-analytics',
          builder: (context, state) => const AdminAnalyticsPage(),
        ),
        GoRoute(
          path: '/admin-complaints',
          builder: (context, state) => const AdminComplaintsPage(),
        ),
        GoRoute(
          path: '/admin-menu',
          builder: (context, state) => const AdminMenuPage(),
        ),
        GoRoute(
          path: '/admin-customers',
          builder: (context, state) => const AdminCustomersPage(),
        ),
        GoRoute(
          path: '/admin-reports',
          builder: (context, state) => const AdminReportsPage(),
        ),
        GoRoute(
          path: '/admin-delivery',
          builder: (context, state) => const AdminDeliveryPage(),
        ),
        GoRoute(
          path: '/admin-settings',
          builder: (context, state) => const AdminSettingsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/help-support',
          builder: (context, state) => const HelpSupportPage(),
        ),
        GoRoute(
          path: '/user-complaints',
          builder: (context, state) => const UserComplaintsPage(),
        ),
        GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) => const OAuthCallbackPage(),
        ),
        GoRoute(
          path: '/auth/v1/callback',
          builder: (context, state) => const OAuthCallbackPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) {
            // Check if this is an OAuth callback with code parameter
            final uri = Uri.parse(state.uri.toString());
            if (uri.queryParameters.containsKey('code')) {
              return const OAuthCallbackPage();
            }
            // Default to splash if no code parameter
            return const SplashPage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => _buildProfilePage(),
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final email = state.extra as String?;
            return OtpVerificationPage(email: email ?? '');
          },
        ),
        GoRoute(
          path: '/check-complaint-status',
          builder: (context, state) {
            final email = state.extra as String?;
            return ComplaintStatusCheckPage(prefilledEmail: email);
          },
        ),
        GoRoute(
          path: '/banned',
          builder: (context, state) => _buildBannedPage(context, state),
        ),
        GoRoute(
          path: '/order-tracking',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final orderId = extra?['orderId'] as String? ?? '';
            final orderData =
                extra?['orderData'] as Map<String, dynamic>? ?? {};
            return OrderTrackingPage(orderId: orderId, orderData: orderData);
          },
        ),
        GoRoute(
          path: '/waiter-dashboard',
          builder: (context, state) => const WaiterDashboard(),
        ),
        GoRoute(
          path: '/waiter-take-order',
          builder: (context, state) => const WaiterTakeOrderPage(),
        ),
        GoRoute(
          path: '/waiter-orders',
          builder: (context, state) => const WaiterOrdersPage(),
        ),
        GoRoute(
          path: '/waiter-tables',
          builder: (context, state) => const WaiterTablesPage(),
        ),
        GoRoute(
          path: '/waiter-bills',
          builder: (context, state) => const WaiterBillsPage(),
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    // The redirect logic in _handleRedirect will handle authentication checks
    // This method just returns the profile page
    return const ProfilePage();
  }

  Widget _buildBannedPage(BuildContext context, GoRouterState state) {
    final email = state.extra as String?;
    return BannedPage(userEmail: email);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while determining initial location
    if (widget.isLoggedIn && !_locationDetermined) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.orange)),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Pizza Time',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      routerConfig: _buildRouter(),
    );
  }
}
