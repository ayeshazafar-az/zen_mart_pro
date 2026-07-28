import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'vendor_analytics_screen.dart';
import 'view_vendor_reviews_screen.dart';
import '../../../shared_features/profile/edit_profile_screen.dart';
import '../../../shared_features/widgets/safe_image.dart';
import '../../customer/presentation/help_support_screen.dart';
import '../../../core/theme/theme_provider.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildProfileIcon(bool isActive) {
      if (user.profileImageUrl == null || user.profileImageUrl!.isEmpty) {
        return Icon(Icons.person,
            color: isActive ? Colors.orange : Colors.grey);
      }
      return Container(
        padding: EdgeInsets.all(isActive ? 2 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: ClipOval(
          child: SizedBox(
            width: 24,
            height: 24,
            child: SafeImage(
              imageUrl: user.profileImageUrl!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    final List<Widget> screens = [
      _VendorHomeTab(user: user),
      const ManageVendorOrdersScreen(),
      const ManageVendorProductsScreen(),
      const _VendorSettingsTab(),
      EditProfileScreen(user: user),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Products'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
            icon: buildProfileIcon(false),
            activeIcon: buildProfileIcon(true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _VendorHomeTab extends StatelessWidget {
  final dynamic user;
  const _VendorHomeTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
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
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.store, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? "Vendor"}!',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ViewVendorReviewsScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 30),
                          SizedBox(height: 10),
                          Text('Reviews',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VendorAnalyticsScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.analytics, color: Colors.blue, size: 30),
                          SizedBox(height: 10),
                          Text('Analytics',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDashboardStats(context),
            const SizedBox(height: 40),
            const Center(child: ZenvyroBrandingWidget(compact: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStats(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .where('vendorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, shopSnapshot) {
        if (!shopSnapshot.hasData || shopSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final shopId = shopSnapshot.data!.docs.first.id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('shopId', isEqualTo: shopId)
              .snapshots(),
          builder: (context, orderSnapshot) {
            if (!orderSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            double totalRevenue = 0;
            int totalOrders = 0;
            final orders = orderSnapshot.data!.docs.toList();

            // Sort by date locally to avoid composite index requirement
            orders.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            for (var doc in orders) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString();

              // Exclude cancelled and rejected orders from stats
              if (status != 'Cancelled' && status != 'Rejected') {
                totalOrders++;
                double subtotal =
                    double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0;
                if (subtotal == 0) {
                  subtotal =
                      double.tryParse(data['totalAmount']?.toString() ?? '0') ??
                          0;
                }
                totalRevenue += subtotal;
              }
            }

            // Exclude rejected/cancelled from recent orders list to not clutter the view
            final recentValidOrders = orders.where((doc) {
              final status =
                  (doc.data() as Map<String, dynamic>)['status']?.toString();
              return status != 'Cancelled' && status != 'Rejected';
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Revenue',
                        value: 'Rs. ${totalRevenue.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Orders',
                        value: totalOrders.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (recentValidOrders.isNotEmpty) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Orders',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (recentValidOrders.length > 5)
                        ? 5
                        : recentValidOrders.length,
                    itemBuilder: (context, index) {
                      final doc = recentValidOrders[index];
                      final data = doc.data() as Map<String, dynamic>;
                      double amount = double.tryParse(
                              data['subtotal']?.toString() ?? '0') ??
                          0;
                      if (amount == 0) {
                        amount = double.tryParse(
                                data['totalAmount']?.toString() ?? '0') ??
                            0;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.receipt, color: Colors.white),
                          ),
                          title: Text(
                              'Order #${doc.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(data['status'] ?? 'Pending'),
                          trailing: Text(
                            'Rs. ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green),
                          ),
                        ),
                      );
                    },
                  )
                ]
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 2,
          )
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _VendorSettingsTab extends StatelessWidget {
  const _VendorSettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            context,
            'Manage Assigned Shop',
            'Update location and contact info',
            Icons.storefront,
            const ManageAssignedShopScreen(),
          ),
          _buildSettingsTile(
            context,
            'Manage Categories',
            'Organize your shop structure',
            Icons.category,
            const ManageVendorCategoriesScreen(),
          ),
          _buildSettingsTile(
            context,
            'Shop Banner',
            'Upload a promotional image',
            Icons.image,
            const ManageVendorShopBannerScreen(),
          ),
          _buildSettingsTile(
            context,
            'Help & Support',
            'Contact Admin for assistance',
            Icons.help,
            const HelpSupportScreen(),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.dark_mode, color: Colors.orange),
                  ),
                  title: const Text('Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Toggle application theme',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, String subtitle,
      IconData icon, Widget screen) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.orange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
