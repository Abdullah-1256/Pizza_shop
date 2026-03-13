import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigation_helper.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // 🔹 White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // On home page, show exit dialog when back button is pressed
            NavigationHelper.handleBackButton(
              context,
              fallbackRoute: '/product',
              showExitDialog: false, // Skip exit dialog for now
            );
          },
        ),
        title: Text(
          "Pizza Time",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          /// 🔹 Background image (small height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.45, // 👈 Image height 45% of screen
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login.webp'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),

          /// 🔹 Foreground content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Skip button on top-right (over image)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () =>
                          NavigationHelper.safePush(context, '/product'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                /// Bottom white card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1542281286-9e0a16bb7366?w=300',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pizza for you',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Everyday new pizza\neat fresh pizza',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      /// Email button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              NavigationHelper.safePush(context, '/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4E6D6),
                            foregroundColor: AppTheme.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Sign up with Email'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Google button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFC23C), Color(0xFFFF8F26)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: () =>
                              NavigationHelper.safePush(context, '/login'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Sign up with Google',
                            style: TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}
