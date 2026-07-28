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
  final user;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.analytics, color: Colors.blue, size: 30),
                        SizedBox(height: 10),
                        Text('Analytics',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Center(child: ZenvyroBrandingWidget(compact: true)),
          ],
        ),
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
