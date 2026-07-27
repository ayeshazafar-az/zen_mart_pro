import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import 'available_orders_screen.dart';
import 'active_delivery_screen.dart';
import 'delivery_history_screen.dart';
import 'earnings_dashboard_screen.dart';
import '../../../shared_features/profile/edit_profile_screen.dart';
import '../../../shared_features/widgets/safe_image.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
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

    final List<Widget> _screens = [
      const AvailableOrdersScreen(),
      const ActiveDeliveryScreen(),
      const DeliveryHistoryScreen(),
      const EarningsDashboardScreen(),
      EditProfileScreen(user: user),
    ];

    return Scaffold(
      appBar: _currentIndex == 4
          ? null
          : AppBar(
              title: const Text('Rider Portal'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining), label: 'Available'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.directions_bike), label: 'Active'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
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
