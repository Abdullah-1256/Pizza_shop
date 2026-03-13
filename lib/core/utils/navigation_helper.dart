import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation helper for proper back button handling
class NavigationHelper {
  /// Handle system back button press
  static Future<bool> handleBackButton(
    BuildContext context, {
    String? fallbackRoute,
    bool showExitDialog = false,
  }) async {
    // If we can pop the route, do it (this preserves navigation stack)
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return true;
    }

    // If there's a fallback route and we're at the root
    if (fallbackRoute != null && isAtRoot(context)) {
      // Go to fallback route instead of exiting
      context.go(fallbackRoute);
      return true;
    }

    // Show exit confirmation dialog if requested
    if (showExitDialog && isAtRoot(context)) {
      return await _showExitDialog(context);
    }

    // Default behavior - don't exit
    return false;
  }

  /// Show exit confirmation dialog
  static Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Exit'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Safe navigation with push (preserves back button stack)
  static void safePush(BuildContext context, String route, {Object? extra}) {
    context.push(route, extra: extra);
  }

  /// Safe navigation with go (replaces current route)
  static void safeGo(BuildContext context, String route, {Object? extra}) {
    context.go(route, extra: extra);
  }

  /// Safe navigation with pop (goes back to previous screen)
  static void safePop(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    }
  }

  /// Check if current route is the initial route
  static bool isAtRoot(BuildContext context) {
    final currentLocation = GoRouter.of(
      context,
    ).routeInformationProvider.value.location;
    return currentLocation == '/' ||
        currentLocation == '/splash' ||
        currentLocation == '/home';
  }
}
