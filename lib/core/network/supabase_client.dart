import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  // Authentication state management
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Token refresh and session management
  static Future<void> ensureAuthenticated() async {
    final session = client.auth.currentSession;
    if (session == null) {
      throw Exception('No active session');
    }

    // Check if token is expired or will expire soon (within 5 minutes)
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final timeUntilExpiry = expiresAt - now;

      // If token expires within 5 minutes, refresh it
      if (timeUntilExpiry < 300) {
        print('🔄 Token expiring soon, refreshing...');
        await client.auth.refreshSession();
        print('✅ Token refreshed successfully');
      }
    }
  }

  // Generic method to execute Supabase operations with automatic retry on auth errors
  static Future<T> executeWithAuthRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        await ensureAuthenticated();
        return await operation();
      } on AuthException catch (e) {
        if (e.message.contains('JWT') && attempts < maxRetries) {
          print('🔄 JWT error detected, attempting refresh...');
          try {
            await client.auth.refreshSession();
            attempts++;
            continue;
          } catch (refreshError) {
            print('❌ Failed to refresh token: $refreshError');
            rethrow;
          }
        } else {
          rethrow;
        }
      } catch (e) {
        if (e.toString().contains('JWT') && attempts < maxRetries) {
          print('🔄 JWT error in operation, attempting refresh...');
          try {
            await client.auth.refreshSession();
            attempts++;
            continue;
          } catch (refreshError) {
            print('❌ Failed to refresh token: $refreshError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Profile management
  static Future<void> createOrUpdateProfile({
    required String userId,
    required String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    String? role,
  }) async {
    return executeWithAuthRetry(() async {
      // Check if profile already exists
      final existingProfile = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      // Determine role based on email if not provided and not already set
      String userRole = role ?? existingProfile?['role'] ?? 'customer';
      if (email != null && existingProfile?['role'] == null) {
        if (email == 'abdullahmubashar280@gmail.com') {
          userRole = 'admin';
        } else if (email == 'waiter1@gmail.com') {
          userRole = 'waiter';
        }
      }

      await client.from('profiles').upsert({
        'id': userId,
        'email': email,
        'full_name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': userRole,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return executeWithAuthRetry(() async {
      return await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    });
  }

  // Orders management with auth retry
  static Future<List<Map<String, dynamic>>> getOrders() async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  static Future<List<Map<String, dynamic>>> getAdminOrdersView() async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('vw_admin_orders')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  // Products management - no auth required for viewing products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await client
          .from('products')
          .select('*')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      // Filter out products that don't have valid uploaded images
      // Only show products with URLs (uploaded images), not asset paths
      final products = List<Map<String, dynamic>>.from(response);
      final filteredProducts = products.where((product) {
        final imageUrl = product['image_url'];
        // Only include products with valid uploaded image URLs
        return imageUrl != null &&
            imageUrl.toString().isNotEmpty &&
            (imageUrl.toString().startsWith('http://') ||
                imageUrl.toString().startsWith('https://'));
      }).toList();

      print(
        '📊 Filtered products: ${filteredProducts.length}/${products.length} have valid images',
      );
      return filteredProducts;
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> product,
  ) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('products')
          .insert(product)
          .select()
          .single();
      return response;
    });
  }

  static Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    return executeWithAuthRetry(() async {
      await client
          .from('products')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);
    });
  }

  static Future<void> deleteProduct(String productId) async {
    return executeWithAuthRetry(() async {
      await client.from('products').delete().eq('id', productId);
    });
  }

  // Complaints management with auth retry
  static Future<List<Map<String, dynamic>>> getComplaints() async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('complaints')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  static Future<List<Map<String, dynamic>>> getUserComplaints(
    String userId,
  ) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('complaints')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  static Future<Map<String, dynamic>> addComplaint(
    Map<String, dynamic> complaint,
  ) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('complaints')
          .insert(complaint)
          .select()
          .single();
      return response;
    });
  }

  static Future<Map<String, dynamic>?> getComplaintByEmailAndTrackingCode(
    String email,
    String trackingCode,
  ) async {
    try {
      final response = await client
          .from('complaints')
          .select()
          .eq('user_email', email)
          .eq('tracking_code', trackingCode)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Error fetching complaint: $e');
      return null;
    }
  }

  static Future<void> updateComplaint(
    String complaintId,
    Map<String, dynamic> updates,
  ) async {
    return executeWithAuthRetry(() async {
      await client
          .from('complaints')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', complaintId);
    });
  }

  // Order management with auth retry
  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> order,
  ) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('orders')
          .insert(order)
          .select()
          .single();
      return response;
    });
  }

  static Future<List<Map<String, dynamic>>> createOrderItems(
    List<Map<String, dynamic>> orderItems,
  ) async {
    return executeWithAuthRetry(() async {
      final response = await client
          .from('order_items')
          .insert(orderItems)
          .select();
      return List<Map<String, dynamic>>.from(response);
    });
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    return executeWithAuthRetry(() async {
      await client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    });
  }

  // Delivery assignment management
  static Future<String?> assignDeliveryPerson(String orderId) async {
    return executeWithAuthRetry(() async {
      try {
        final response = await client.rpc(
          'assign_delivery_person',
          params: {'p_order_id': orderId},
        );

        if (response != null) {
          print('✅ Delivery person assigned to order $orderId: $response');
          return response.toString();
        }
        return null;
      } catch (e) {
        print('❌ Error assigning delivery person: $e');
        return null;
      }
    });
  }

  // Image upload to Supabase storage
  static Future<String?> uploadProductImage(
    XFile xFile,
    String fileName,
  ) async {
    try {
      // Read file as bytes - works for both mobile and web
      final bytes = await xFile.readAsBytes();
      final fileExtension = fileName.split('.').last;
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      print('📤 Uploading to bucket: images, file: $uniqueFileName');

      // Upload to 'images' bucket using uploadBinary
      try {
        final storage = client.storage.from('images');

        await storage.uploadBinary(
          uniqueFileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

        // Get public URL
        final publicUrl = storage.getPublicUrl(uniqueFileName);
        print('✅ Public URL generated: $publicUrl');
        return publicUrl;
      } catch (bucketError) {
        print('❌ images bucket failed: $bucketError');
        print('🔍 Bucket error details: ${bucketError.toString()}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
}
