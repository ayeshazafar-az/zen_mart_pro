import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import 'browse_shops_screen.dart';
import 'shopping_cart_screen.dart';
import 'order_history_screen.dart';
import 'customer_profile_menu_screen.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/widgets/safe_image.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      CustomerDashboardScreenState();
}

class CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    CustomerHomeScreen(),
    BrowseShopsScreen(),
    ShoppingCartScreen(),
    OrderHistoryScreen(),
    CustomerProfileMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    Widget buildProfileIcon(bool isActive) {
      if (user == null ||
          user.profileImageUrl == null ||
          user.profileImageUrl!.isEmpty) {
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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.store), label: 'Shops'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Orders'),
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
