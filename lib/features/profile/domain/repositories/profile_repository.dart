import '../entities/user_profile.dart';
import '../entities/user_address.dart';
import '../entities/user_payment_method.dart';
import '../entities/order.dart';
import '../entities/user_notifications.dart';

abstract class ProfileRepository {
  // User Profile
  Future<UserProfile?> getUserProfile(String userId);
  Future<UserProfile> updateUserProfile(UserProfile profile);

  // User Addresses
  Future<List<UserAddress>> getUserAddresses(String userId);
  Future<UserAddress> addUserAddress(UserAddress address);
  Future<UserAddress> updateUserAddress(UserAddress address);
  Future<void> deleteUserAddress(String addressId);
  Future<void> setDefaultAddress(String addressId, String userId);

  // Payment Methods
  Future<List<UserPaymentMethod>> getUserPaymentMethods(String userId);
  Future<UserPaymentMethod> addPaymentMethod(UserPaymentMethod paymentMethod);
  Future<void> deletePaymentMethod(String paymentMethodId);
  Future<void> setDefaultPaymentMethod(String paymentMethodId, String userId);

  // Orders
  Future<List<Order>> getUserOrders(String userId);
  Future<Order> getOrderDetails(String orderId);

  // Notifications
  Future<UserNotifications?> getUserNotifications(String userId);
  Future<UserNotifications> updateUserNotifications(
    UserNotifications notifications,
  );
}
