import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/zenvyro_branding_widget.dart';
import 'create_shop_screen.dart';
import 'create_vendor_screen.dart';
import 'create_vendor_shop_screen.dart';
import 'manage_vendors_screen.dart';
import 'manage_customers_screen.dart';
import 'manage_riders_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_shop_banners_screen.dart';
import 'view_all_shops_screen.dart';
import 'view_all_products_screen.dart';
import 'view_all_orders_screen.dart';
import 'handle_complaints_screen.dart';
import 'view_reports_analytics_screen.dart';
import 'manage_approvals_screen.dart';
import 'manage_banner_approvals_screen.dart';
import '../../../shared_features/profile/edit_profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Super Admin Portal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amber : Colors.blueGrey),
              Switch(
                value: isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                activeColor: Colors.amber,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F2027),
                    const Color(0xFF203A43),
                    const Color(0xFF2C5364)
                  ]
                : [
                    const Color(0xFFE0EAFC),
                    const Color(0xFFCFDEF3)
                  ], // Soft minimalist gradients
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Glass Welcome Header
                _buildGlassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.lightBlue]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              size: 35, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, ${user?.name ?? "Admin"}!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user?.role.toUpperCase() ??
                                      AppConstants.roleSuperAdmin.toUpperCase(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, size: 28),
                          color: isDark ? Colors.white70 : Colors.blueGrey,
                          onPressed: () {
                            if (user != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfileScreen(user: user)));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Ecosystem Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Redesigned Grid with Premium Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05, // Slightly taller
                  children: [
                    _buildGlassActionCard(context,
                        title: 'User Approvals',
                        icon: Icons.domain_verification,
                        subtitle: 'Approve personnel',
                        iconColor: Colors.tealAccent.shade400,
                        destination: const ManageApprovalsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Banner Approvals',
                        icon: Icons.collections,
                        subtitle: 'Review banners',
                        iconColor: Colors.orangeAccent,
                        destination: const ManageBannerApprovalsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Quick Onboard',
                        icon: Icons.bolt,
                        subtitle: 'Vendor & Shop combo',
                        iconColor: Colors.amberAccent,
                        destination: const CreateVendorShopScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Create Shop',
                        icon: Icons.storefront,
                        subtitle: 'New shop entry',
                        iconColor: Colors.blueAccent,
                        destination: const CreateShopScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Create Vendor',
                        icon: Icons.person_add,
                        subtitle: 'New vendor account',
                        iconColor: Colors.purpleAccent,
                        destination: const CreateVendorScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Vendors',
                        icon: Icons.supervisor_account,
                        subtitle: 'Manage all vendors',
                        iconColor: Colors.indigoAccent,
                        destination: const ManageVendorsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Customers',
                        icon: Icons.people_alt_outlined,
                        subtitle: 'View user base',
                        iconColor: Colors.lightGreenAccent.shade400,
                        destination: const ManageCustomersScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Riders',
                        icon: Icons.delivery_dining,
                        subtitle: 'Delivery personnel',
                        iconColor: Colors.redAccent,
                        destination: const ManageRidersScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Categories',
                        icon: Icons.category,
                        subtitle: 'Catalog types',
                        iconColor: Colors.pinkAccent,
                        destination: const ManageCategoriesScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Shop Banners',
                        icon: Icons.image,
                        subtitle: 'Promotional visuals',
                        iconColor: Colors.cyanAccent,
                        destination: const ManageShopBannersScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'All Shops',
                        icon: Icons.store,
                        subtitle: 'Ecosystem stores',
                        iconColor: Colors.deepOrangeAccent,
                        destination: const ViewAllShopsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'All Products',
                        icon: Icons.shopping_bag,
                        subtitle: 'Platform catalog',
                        iconColor: Colors.limeAccent.shade700,
                        destination: const ViewAllProductsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'All Orders',
                        icon: Icons.receipt_long,
                        subtitle: 'Global transactions',
                        iconColor: Colors.blue,
                        destination: const ViewAllOrdersScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Complaints',
                        icon: Icons.report_problem_outlined,
                        subtitle: 'Dispute tickets',
                        iconColor: Colors.red,
                        destination: const HandleComplaintsScreen(),
                        isDark: isDark),
                    _buildGlassActionCard(context,
                        title: 'Analytics',
                        icon: Icons.analytics,
                        subtitle: 'Platform statistics',
                        iconColor: Colors.lightBlueAccent,
                        destination: const ViewReportsAnalyticsScreen(),
                        isDark: isDark),
                  ],
                ),
                const SizedBox(height: 40),
                const Center(child: ZenvyroBrandingWidget(compact: true)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(
      {required Widget child, required bool isDark, double borderRadius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String subtitle,
    required Color iconColor,
    required Widget destination,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: iconColor.withValues(alpha: 0.2),
      highlightColor: iconColor.withValues(alpha: 0.1),
      child: _buildGlassCard(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const Spacer(),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
