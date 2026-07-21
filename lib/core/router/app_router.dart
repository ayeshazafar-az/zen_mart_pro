import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../constants/zenvyro_branding_widget.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final user = authProvider.currentUser;
        final isLoggedIn = user != null;
        final isLoggingIn = state.uri.toString() == '/login';

        if (!isLoggedIn) {
          return '/login';
        }

        if (isLoggingIn) {
          switch (user.role) {
            case 'super_admin':
              return '/admin-dashboard';
            case 'vendor':
              return '/vendor-dashboard';
            case 'rider':
              return '/rider-dashboard';
            case 'customer':
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
          path: '/admin-dashboard',
          builder: (context, state) => const RoleDashboardScaffold(roleTitle: 'Super Admin Dashboard'),
        ),
        GoRoute(
          path: '/vendor-dashboard',
          builder: (context, state) => const RoleDashboardScaffold(roleTitle: 'Vendor Shop Dashboard'),
        ),
        GoRoute(
          path: '/rider-dashboard',
          builder: (context, state) => const RoleDashboardScaffold(roleTitle: 'Rider Delivery Dashboard'),
        ),
        GoRoute(
          path: '/customer-home',
          builder: (context, state) => const RoleDashboardScaffold(roleTitle: 'Customer Marketplace Home'),
        ),
      ],
    );
  }
}

class RoleDashboardScaffold extends StatelessWidget {
  final String roleTitle;
  const RoleDashboardScaffold({super.key, required this.roleTitle});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(roleTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Welcome, ${authProvider.currentUser?.name ?? "User"}!\nRole: ${authProvider.currentUser?.role}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          const ZenvyroBrandingWidget(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}