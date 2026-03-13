class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://awrnmnjoedpkyohirekt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cm5tbmpvZWRwa3lvaGlyZWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1OTY4NzAsImV4cCI6MjA3ODE3Mjg3MH0.n61fdWDvCtJieY4GXZdFBjl_KOR7i2axOrlXiQcdvOU';

  // Pusher Configuration
  static const String pusherAppKey = 'your_pusher_app_key_here';
  static const String pusherCluster = 'mt1'; // Change to your cluster
  static const String pusherHost =
      'your_pusher_host_here'; // For self-hosted Pusher
  static const int pusherPort = 443;
  static const bool pusherEncrypted = true;

  // OAuth Redirect URLs
  static const String oauthRedirectUrl =
      'com.coffeeshop.coffee_shop://auth/callback';

  // App Information
  static const String appName = 'Pizza Time';
  static const String appVersion = '1.0.0';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int otpLength = 6;

  // Cache Keys
  static const String userTokenKey = 'user_token';
  static const String userProfileKey = 'user_profile';
  static const String cartItemsKey = 'cart_items';
  static const String favoriteItemsKey = 'favorite_items';

  // Database Table Names
  static const String profilesTable = 'profiles';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String userAddressesTable = 'user_addresses';

  // Storage Bucket Names
  static const String avatarsBucket = 'avatars';
  static const String productImagesBucket = 'product_images';
}
