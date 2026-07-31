import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash_onboarding/presentation/splash_screen.dart';
import '../../features/splash_onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/customer/dashboard/presentation/customer_home_screen.dart';
import '../../features/customer/delivery_request/presentation/create_delivery_screen.dart';
import '../../features/customer/rider_matching/presentation/rider_matching_screen.dart';
import '../../features/customer/live_tracking/presentation/live_tracking_screen.dart';
import '../../features/customer/order_completion/presentation/order_completion_screen.dart';
import '../../features/rider/dashboard/presentation/rider_home_screen.dart';
import '../../features/rider/job_details/presentation/delivery_job_details_screen.dart';
import '../../features/rider/navigation/presentation/rider_navigation_screen.dart';
import '../../features/rider/earnings/presentation/rider_earnings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/profile/presentation/security_screen.dart';
import '../../features/profile/presentation/language_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';
import '../../features/wallet/presentation/deposit_screen.dart';


final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final authState = container.read(authNotifierProvider);
      final user = authState.user;

      if (user != null) {
        final loc = state.uri.path;
        final isCustomerRoute = loc == '/customer' ||
            loc == '/create-delivery' ||
            loc == '/rider-matching' ||
            loc == '/live-tracking' ||
            loc == '/order-completion' ||
            loc == '/deposit';


        final isRiderRoute = loc == '/rider' ||
            loc == '/job-details' ||
            loc == '/rider-navigation' ||
            loc == '/earnings';

        // A rider must NEVER land on customer dashboard or request delivery screens
        if (user.isRider && isCustomerRoute) {
          return '/rider';
        }

        // A customer must NEVER land on rider dashboard or earnings screens
        if (user.isCustomer && isRiderRoute) {
          return '/customer';
        }
      }
    } catch (_) {
      // Ignore during initial setup
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/customer',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/create-delivery',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        return CreateDeliveryScreen(initialPackageType: type);
      },
    ),
    GoRoute(
      path: '/rider-matching',
      builder: (context, state) => const RiderMatchingScreen(),
    ),
    GoRoute(
      path: '/live-tracking',
      builder: (context, state) => const LiveTrackingScreen(),
    ),
    GoRoute(
      path: '/order-completion',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        return OrderCompletionScreen(deliveryId: id);
      },
    ),
    GoRoute(
      path: '/rider',
      builder: (context, state) => const RiderHomeScreen(),
    ),
    GoRoute(
      path: '/job-details',
      builder: (context, state) => const DeliveryJobDetailsScreen(),
    ),
    GoRoute(
      path: '/rider-navigation',
      builder: (context, state) => const RiderNavigationScreen(),
    ),
    GoRoute(
      path: '/earnings',
      builder: (context, state) => const RiderEarningsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    // Short Aliases
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/security',
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    // Settings Nested Routes
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/deposit',
      builder: (context, state) => const DepositScreen(),
    ),

  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
