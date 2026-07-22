import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/super_admin/presentation/admin_dashboard_screen.dart';
import '../../features/vendor/presentation/vendor_dashboard_screen.dart';
import '../../features/rider/presentation/rider_dashboard_screen.dart';
import '../../features/customer/presentation/customer_home_screen.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final user = authProvider.currentUser;
        final isLoggedIn = user != null;
        final path = state.uri.toString();

        // Added '/otp' to the list of authentication routes
        final isAuthRoute = path == '/login' || path == '/signup' || path == '/otp';

        // Redirect to login if not authenticated and trying to access protected routes
        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
        }

        // Redirect to appropriate dashboard if already logged in and on an auth page
        if (isLoggedIn && isAuthRoute) {
          switch (user.role) {
            case AppConstants.roleSuperAdmin:
              return '/admin-dashboard';
            case AppConstants.roleVendor:
              return '/vendor-dashboard';
            case AppConstants.roleRider:
              return '/rider-dashboard';
            case AppConstants.roleCustomer:
            default:
              return '/customer-home';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpVerificationScreen(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/vendor-dashboard',
          builder: (context, state) => const VendorDashboardScreen(),
        ),
        GoRoute(
          path: '/rider-dashboard',
          builder: (context, state) => const RiderDashboardScreen(),
        ),
        GoRoute(
          path: '/customer-home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),
      ],
    );
  }
}