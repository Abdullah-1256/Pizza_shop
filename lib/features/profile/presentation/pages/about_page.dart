import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          "About",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo/Brand Section
            Container(
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
            const SizedBox(height: 20),

            Text(
              'Pizza Time',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // About Description
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
                children: [
                  Text(
                    'About Pizza Time',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pizza Time is your go-to app for delicious, freshly baked pizzas delivered right to your doorstep. We pride ourselves on using the finest ingredients, traditional recipes, and lightning-fast delivery to bring you the perfect pizza experience every time.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Features
            Text(
              'What We Offer',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.delivery_dining,
              title: 'Fast Delivery',
              description: 'Hot and fresh pizzas delivered in under 30 minutes',
            ),

            _buildFeatureCard(
              icon: Icons.restaurant,
              title: 'Quality Ingredients',
              description: 'Premium ingredients sourced from trusted suppliers',
            ),

            _buildFeatureCard(
              icon: Icons.star,
              title: 'Custom Orders',
              description:
                  'Create your perfect pizza with our customization options',
            ),

            _buildFeatureCard(
              icon: Icons.security,
              title: 'Secure Payments',
              description:
                  'Multiple secure payment options for your convenience',
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
                children: [
                  Text(
                    'Get in Touch',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.location_on,
                    title: 'Visit Us',
                    value: '123 Pizza Street, Lahore, Pakistan',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Call Us',
                    value: '+92 300 123 4567',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: 'hello@pizzatime.com',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Website',
                    value: 'www.pizzatime.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Social Media
            Text(
              'Follow Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(icon: Icons.facebook, label: 'Facebook'),
                const SizedBox(width: 16),
                _buildSocialButton(icon: Icons.camera_alt, label: 'Instagram'),
                const SizedBox(width: 16),
                _buildSocialButton(icon: Icons.chat, label: 'Twitter'),
              ],
            ),
            const SizedBox(height: 30),

            // Legal Links
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
                children: [
                  _buildLegalLink('Privacy Policy'),
                  const Divider(),
                  _buildLegalLink('Terms of Service'),
                  const Divider(),
                  _buildLegalLink('Refund Policy'),
                  const Divider(),
                  _buildLegalLink('Licenses'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Copyright
            Text(
              '© 2024 Pizza Time. All rights reserved.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
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

  Widget _buildSocialButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.black38,
        size: 16,
      ),
      onTap: () {
        // TODO: Navigate to respective legal pages
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
