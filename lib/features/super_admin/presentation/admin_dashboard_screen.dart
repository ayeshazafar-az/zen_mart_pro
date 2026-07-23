import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/zenvyro_branding_widget.dart';
import 'create_shop_screen.dart';
import 'create_vendor_screen.dart';
import 'create_vendor_shop_screen.dart'; // Combo workflow screen
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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // GoRouter will automatically intercept the state change and route to '/login'
              authProvider.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user?.name ?? "Admin"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${user?.role ?? AppConstants.roleSuperAdmin}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ecosystem & Storefront Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Grid of Management Options with shrinkWrap for scrolling safety
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: const [
                // Pending Approvals Card prioritized at the top
                _AdminDashboardCard(
                  title: 'Pending Approvals',
                  icon: Icons.domain_verification,
                  subtitle: 'Approve riders & vendors',
                  destination: ManageApprovalsScreen(),
                ),
                // Combo Workflow: Create both Vendor and Shop simultaneously
                _AdminDashboardCard(
                  title: 'Quick Vendor & Shop',
                  icon: Icons.bolt,
                  subtitle: 'All-in-one onboarding',
                  destination: CreateVendorShopScreen(),
                ),
                // Separate Workflow: Create independent Shop
                _AdminDashboardCard(
                  title: 'Create Shop',
                  icon: Icons.storefront,
                  subtitle: 'Assign shop to vendor',
                  destination: CreateShopScreen(),
                ),
                // Separate Workflow: Create independent Vendor account
                _AdminDashboardCard(
                  title: 'Create Vendor',
                  icon: Icons.person_add,
                  subtitle: 'Add vendor credentials',
                  destination: CreateVendorScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Manage Vendors',
                  icon: Icons.supervisor_account,
                  subtitle: 'View & manage vendors',
                  destination: ManageVendorsScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Manage Customers',
                  icon: Icons.people_alt_outlined,
                  subtitle: 'View platform customers',
                  destination: ManageCustomersScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Manage Riders',
                  icon: Icons.delivery_dining,
                  subtitle: 'View delivery staff',
                  destination: ManageRidersScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Categories',
                  icon: Icons.category_outlined,
                  subtitle: 'Manage marketplace catalog',
                  destination: ManageCategoriesScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Shop Banners',
                  icon: Icons.image,
                  subtitle: 'Manage promotional banners',
                  destination: ManageShopBannersScreen(),
                ),
                _AdminDashboardCard(
                  title: 'All Shops',
                  icon: Icons.store,
                  subtitle: 'View all active shops',
                  destination: ViewAllShopsScreen(),
                ),
                _AdminDashboardCard(
                  title: 'All Products',
                  icon: Icons.shopping_bag,
                  subtitle: 'View platform products',
                  destination: ViewAllProductsScreen(),
                ),
                _AdminDashboardCard(
                  title: 'All Orders',
                  icon: Icons.receipt_long,
                  subtitle: 'Monitor all transactions',
                  destination: ViewAllOrdersScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Complaints',
                  icon: Icons.report_problem_outlined,
                  subtitle: 'Resolve dispute tickets',
                  destination: HandleComplaintsScreen(),
                ),
                _AdminDashboardCard(
                  title: 'Analytics & Reports',
                  icon: Icons.analytics,
                  subtitle: 'Platform metrics & stats',
                  destination: ViewReportsAnalyticsScreen(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Center(child: ZenvyroBrandingWidget(compact: true)),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final Widget destination;

  const _AdminDashboardCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}