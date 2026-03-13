import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../../../core/network/supabase_client.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  String? _profileImageUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Load user data from local storage
      final userProfile = await SharedPreferencesHelper.getUserProfile();

      if (userProfile != null) {
        setState(() {
          _nameController.text = userProfile['name'] ?? '';
          _emailController.text = userProfile['email'] ?? '';
          _phoneController.text = userProfile['phone'] ?? '';
          _profileImageUrl = userProfile['photoUrl'];
        });
      }

      // Also try to load from database for latest data
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final dbProfile = await SupabaseService.getUserProfile(currentUser.id);
        if (dbProfile != null) {
          setState(() {
            _nameController.text =
                dbProfile['full_name'] ??
                _nameController.text; // Map 'full_name' to 'name'
            _emailController.text = dbProfile['email'] ?? _emailController.text;
            _phoneController.text = dbProfile['phone'] ?? _phoneController.text;
            _profileImageUrl =
                dbProfile['avatar_url']; // Add avatar_url support
          });
        }
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
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
            onPressed: () => context.go('/profile'),
          ),
          title: Text(
            "Personal Information",
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
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          "Personal Information",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : _profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color:
                              _selectedImage == null && _profileImageUrl == null
                              ? Colors.orange.withOpacity(0.2)
                              : null,
                          border: Border.all(color: Colors.orange, width: 3),
                        ),
                        child:
                            (_selectedImage == null && _profileImageUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.orange,
                              )
                            : null,
                      ),
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
              const SizedBox(height: 30),

              // Form Fields
              Text(
                'Full Name',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your full name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your phone number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
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
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            if (_selectedImage != null || _profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _profileImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        final currentUser = SupabaseService.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Upload image to Supabase Storage if selected
        String? imageUrl;
        if (_selectedImage != null) {
          try {
            final fileName =
                '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final response = await SupabaseService.client.storage
                .from('avatars')
                .upload(fileName, _selectedImage!);

            if (response.isNotEmpty) {
              imageUrl = SupabaseService.client.storage
                  .from('avatars')
                  .getPublicUrl(fileName);
            }
          } catch (e) {
            print('❌ Error uploading image: $e');
            // Continue without image if upload fails
          }
        }

        // Update profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: currentUser.id,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        // Update local storage
        await SharedPreferencesHelper.updateUserProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to profile page
        context.go('/profile');
      } catch (e) {
        print('❌ Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
