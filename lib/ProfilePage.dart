import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/utils/shared_preferences_helper.dart';
import 'core/network/supabase_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Load user data from local storage
      final userProfile = await SharedPreferencesHelper.getUserProfile();

      if (userProfile != null) {
        setState(() => _userProfile = userProfile);
      }

      // Also try to load from database for latest data
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final dbProfile = await SupabaseService.getUserProfile(currentUser.id);
        if (dbProfile != null) {
          setState(() {
            _userProfile = {
              ...?_userProfile,
              'name': dbProfile['full_name'] ?? _userProfile?['name'],
              'email': dbProfile['email'] ?? _userProfile?['email'],
              'phone': dbProfile['phone'] ?? _userProfile?['phone'],
              'photoUrl': dbProfile['avatar_url'] ?? _userProfile?['photoUrl'],
            };
          });
        }

        // Check if user is admin
        try {
          final adminCheck = await SupabaseService.client.rpc('is_admin');
          setState(() {
            _isAdmin = adminCheck as bool? ?? false;
          });
        } catch (e) {
          print('Error checking admin status: $e');
        }
      }
    } catch (e) {
      print('❌ Error loading profile for main page: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF5EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF5EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/product'),
          ),
          title: Text(
            "👤 Profile",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/product'),
        ),
        title: Text(
          "👤 Profile",
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
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: _userProfile?['photoUrl'] != null
                          ? DecorationImage(
                              image: NetworkImage(_userProfile!['photoUrl']),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: _userProfile?['photoUrl'] == null
                          ? Colors.orange.withOpacity(0.2)
                          : null,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: _userProfile?['photoUrl'] == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.orange,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Info
            Text(
              _userProfile?['name'] ?? 'User',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userProfile?['email'] ?? 'No email',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              _userProfile?['phone'] ?? 'No phone number',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // Menu Items
            profileMenuItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () => context.go('/personal-info'),
            ),
            profileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Delivery Address',
              onTap: () => context.go('/delivery-address'),
            ),
            profileMenuItem(
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () => context.go('/payment-methods'),
            ),
            profileMenuItem(
              icon: Icons.history,
              title: 'Order History',
              onTap: () => context.go('/order-history'),
            ),
            profileMenuItem(
              icon: Icons.feedback_outlined,
              title: 'My Complaints',
              onTap: () => context.go('/user-complaints'),
            ),
            profileMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => context.go('/notifications'),
            ),
            profileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => context.go('/help-support'),
            ),
            profileMenuItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => context.go('/about'),
            ),
            const SizedBox(height: 20),

            // Logout Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Logout',
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

  Future<void> _logout() async {
    try {
      await SupabaseService.client.auth.signOut();
      await SharedPreferencesHelper.clearAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
        context.go('/login');
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget profileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          padding: const EdgeInsets.all(8),
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
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
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
}
