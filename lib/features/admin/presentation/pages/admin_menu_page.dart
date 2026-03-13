import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../widgets/admin_sidebar.dart';

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _selectedCategory = 'All';
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'All',
    'Pizza',
    'Burger',
    'Shawarma',
    'Pasta',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  // Image handling methods
  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select image',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<XFile?> _showImageSourceDialog() async {
    final completer = Completer<XFile?>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Camera', style: GoogleFonts.poppins()),
                onTap: () async {
                  try {
                    final image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                      maxWidth: 800,
                    );
                    if (image != null) {
                      completer.complete(image);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('❌ Camera error: $e');
                    completer.complete(null);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to access camera: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.poppins()),
                onTap: () async {
                  try {
                    final image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 800,
                    );
                    if (image != null) {
                      completer.complete(image);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('❌ Gallery error: $e');
                    completer.complete(null);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to access gallery: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                completer.complete(null);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  ImageProvider _getImageProvider(String? imagePath) {
    print('📷 Getting image provider for: $imagePath');

    if (imagePath == null || imagePath.isEmpty) {
      print('⚠️ Image path is null or empty, using placeholder');
      return AssetImage('assets/images/splash.jpg');
    }

    try {
      // For network images (http/https)
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        print('🌐 Using NetworkImage for: $imagePath');
        return NetworkImage(imagePath);
      }
      // For file paths (when a new image is selected but not yet uploaded)
      else if (File(imagePath).existsSync()) {
        print('📱 Using FileImage for: $imagePath');
        return FileImage(File(imagePath));
      } else {
        print('⚠️ File does not exist at path: $imagePath');
        return AssetImage('assets/images/splash.jpg');
      }
    } catch (e) {
      print('❌ Error loading image: $e');
      return AssetImage('assets/images/splash.jpg');
    }
  }

  // Data loading methods
  Future<void> _loadMenuItems() async {
    try {
      setState(() => _isLoading = true);

      // Load ALL products from Supabase (including those without images for admin management)
      final response = await SupabaseService.client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(response);

      setState(() {
        _menuItems = products;
        _isLoading = false;
      });

      print(
        '✅ Loaded ${_menuItems.length} products from database (admin view)',
      );
      for (var product in products) {
        print(
          '📷 Product ${product['name']}: image_url=${product['image_url']}',
        );
      }

      // Warn about products without proper images
      final productsWithoutImages = products.where((p) {
        final imageUrl = p['image_url'];
        return imageUrl == null ||
            imageUrl.toString().isEmpty ||
            !imageUrl.toString().startsWith('http');
      }).length;

      if (productsWithoutImages > 0) {
        print('⚠️ $productsWithoutImages products have no uploaded images');
      }
    } catch (e) {
      print('❌ Error loading menu items: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // CRUD operations
  Future<void> _addMenuItem(Map<String, dynamic> itemData) async {
    try {
      setState(() => _isUploading = true);

      // Upload image first if a new one was selected
      if (itemData['image'] != null) {
        final imageUrl = await SupabaseService.uploadProductImage(
          itemData['image'] as XFile,
          '${DateTime.now().millisecondsSinceEpoch}_${(itemData['image'] as XFile).name}',
        );

        if (imageUrl != null) {
          itemData['image_url'] = imageUrl;
        }
      }

      // Remove the temporary image file reference
      itemData.remove('image');

      // Add the product to the database
      await SupabaseService.addProduct(itemData);

      // Refresh the menu items
      await _loadMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${itemData['name']} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding menu item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _updateMenuItem(
    Map<String, dynamic> item,
    Map<String, dynamic> updates,
  ) async {
    try {
      setState(() => _isUploading = true);

      // Handle image upload if a new image was selected
      if (updates['image'] != null) {
        final imageUrl = await SupabaseService.uploadProductImage(
          updates['image'] as XFile,
          '${DateTime.now().millisecondsSinceEpoch}_${(updates['image'] as XFile).name}',
        );

        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
        updates.remove('image');
      }

      // Update the product in the database
      await SupabaseService.updateProduct(item['id'], updates);

      // Refresh the menu items
      await _loadMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${updates['name'] ?? item['name']} updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating menu item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteMenuItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text(
          'Are you sure you want to delete ${item['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isUploading = true);

        // Delete the product from the database
        await SupabaseService.deleteProduct(item['id']);

        // Refresh the menu items
        await _loadMenuItems();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item['name']} deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error deleting menu item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete menu item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> item,
    bool isAvailable,
  ) async {
    try {
      await SupabaseService.updateProduct(item['id'], {
        'is_available': isAvailable,
      });

      // Refresh the menu items
      await _loadMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item['name']} is now ${isAvailable ? 'available' : 'unavailable'}',
            ),
            backgroundColor: isAvailable ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI Components
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first menu item to get started',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Menu Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    print(
      '🖼️ Building card for ${item['name']}: image_url=${item['image_url']}',
    );
    final imageUrl = item['image_url']?.toString();
    final hasValidImage = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: hasValidImage
                  ? Image(
                      image: _getImageProvider(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error loading image: $error');
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Unnamed Item',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? 'No description',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['category'] ?? 'Uncategorized',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: item['is_available'] ?? true,
                      onChanged: (value) => _toggleAvailability(item, value),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showEditItemDialog(item),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteMenuItem(item),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showAddItemDialog() {
    _showItemDialog(null);
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    _showItemDialog(item);
  }

  void _showItemDialog(Map<String, dynamic>? item) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final descriptionController = TextEditingController(
      text: item?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: item?['price']?.toString() ?? '',
    );
    String selectedCategory = item?['category'] ?? 'Pizza';
    XFile? selectedImage;
    String? currentImageUrl = item?['image_url'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Menu Item' : 'Add New Menu Item',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final image = await _showImageSourceDialog();
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = image;
                            currentImageUrl = image.path;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: selectedImage != null || currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image(
                                  image: selectedImage != null
                                      ? (selectedImage!.path.startsWith('blob:')
                                            ? NetworkImage(selectedImage!.path)
                                            : FileImage(
                                                File(selectedImage!.path),
                                              ))
                                      : _getImageProvider(currentImageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Error loading image: $error');
                                    return _buildImagePlaceholder();
                                  },
                                ),
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Price
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .where((c) => c != 'All')
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();
                          final price =
                              double.tryParse(priceController.text) ?? 0.0;
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a name for the item',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final itemData = {
                            'name': name,
                            'description': description,
                            'price': price,
                            'stock': 0, // Default stock value
                            'category': selectedCategory,
                            'is_available': true,
                            'image': selectedImage,
                          };

                          if (isEditing) {
                            await _updateMenuItem(item!, itemData);
                          } else {
                            await _addMenuItem(itemData);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Filtered menu items getter
  List<Map<String, dynamic>> get _filteredMenuItems {
    if (_selectedCategory == 'All') {
      return _menuItems;
    }
    return _menuItems
        .where((item) => item['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      // Use drawer for mobile/tablet, sidebar for desktop
      drawer: isMobile || isTablet
          ? Drawer(
              backgroundColor: Colors.white,
              child: const AdminSidebar(currentRoute: '/admin-menu'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "🍕 Menu",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.orange),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  onPressed: _showAddItemDialog,
                  tooltip: 'Add New Item',
                ),
              ],
            )
          : null,
      body: isMobile || isTablet
          ? _buildMobileTabletContent()
          : _buildDesktopContent(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Sidebar for desktop
        const AdminSidebar(currentRoute: '/admin-menu'),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "🍕 Menu Management",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    Text(
                      'Filter by Category:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.orange.shade100,
                          checkmarkColor: Colors.orange,
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected ? Colors.orange : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Menu Items Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : _filteredMenuItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMenuItems,
                        color: Colors.orange,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _filteredMenuItems.length,
                          itemBuilder: (context, index) {
                            return _buildMenuItemCard(
                              _filteredMenuItems[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletContent() {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Column(
      children: [
        // Category Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Category:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange,
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.orange : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Menu Items Grid - responsive
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _filteredMenuItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMenuItems,
                  color: Colors.orange,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredMenuItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuItemCard(_filteredMenuItems[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
