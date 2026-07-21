import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/zenvyro_branding_widget.dart';
import 'manage_assigned_shop_screen.dart';
import 'manage_vendor_categories_screen.dart';
import 'manage_vendor_products_screen.dart';
import 'manage_vendor_orders_screen.dart';
import 'manage_vendor_shop_banner_screen.dart';
import 'view_vendor_reviews_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
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
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.store, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? "Vendor"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${user?.role ?? AppConstants.roleVendor}',
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
              'Storefront Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Grid of Vendor Modules
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _VendorDashboardCard(
                  title: 'Manage Shop',
                  icon: Icons.storefront,
                  subtitle: 'Update shop info',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageAssignedShopScreen()),
                    );
                  },
                ),
                _VendorDashboardCard(
                  title: 'Products',
                  icon: Icons.shopping_bag,
                  subtitle: 'Add, edit & stock',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageVendorProductsScreen()),
                    );
                  },
                ),
                _VendorDashboardCard(
                  title: 'Orders',
                  icon: Icons.receipt_long,
                  subtitle: 'Receive & update orders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageVendorOrdersScreen()),
                    );
                  },
                ),
                _VendorDashboardCard(
                  title: 'Categories',
                  icon: Icons.category,
                  subtitle: 'Manage categories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageVendorCategoriesScreen()),
                    );
                  },
                ),
                _VendorDashboardCard(
                  title: 'Shop Banner',
                  icon: Icons.image,
                  subtitle: 'Manage banner & promo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageVendorShopBannerScreen()),
                    );
                  },
                ),
                _VendorDashboardCard(
                  title: 'Customer Reviews',
                  icon: Icons.star,
                  subtitle: 'View ratings & feedback',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViewVendorReviewsScreen()),
                    );
                  },
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

class _VendorDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  const _VendorDashboardCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.orange),
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