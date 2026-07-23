import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
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

        final isAuthRoute = path == '/login' || path == '/signup' || path == '/otp';
        final isPendingRoute = path == '/pending-approval';

        // 1. Redirect to login if not authenticated and trying to access protected routes
        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
        }

        // 2. Intercept Unapproved Riders and Vendors
        final requiresApproval = user.role == AppConstants.roleRider || user.role == AppConstants.roleVendor;

        if (requiresApproval && !user.isApproved) {
          // If they need approval but are not approved, lock them to the pending screen
          if (path != '/pending-approval') {
            return '/pending-approval';
          }
          return null; // Stay on pending screen
        }

        // 3. Redirect to appropriate dashboard if already logged in (and approved)
        // while trying to access an auth page or if they were stuck on the pending screen.
        if (isLoggedIn && (isAuthRoute || isPendingRoute)) {
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

        return null; // Let them go to their requested route
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
          path: '/pending-approval',
          builder: (context, state) => const PendingApprovalScreen(),
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