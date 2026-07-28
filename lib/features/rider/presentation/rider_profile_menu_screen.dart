import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/profile/edit_profile_screen.dart';
import '../../customer/presentation/help_support_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/zenvyro_branding_widget.dart';
import '../../../shared_features/widgets/safe_image.dart';

class RiderProfileMenuScreen extends StatelessWidget {
  const RiderProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: ClipOval(
                  child: SafeImage(
                    imageUrl: user.profileImageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user)),
                      );
                    },
                  ),
                  const Divider(),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        secondary:
                            const Icon(Icons.dark_mode, color: Colors.blueGrey),
                        title: const Text('Dark Mode'),
                        value: themeProvider.isDarkMode,
                        onChanged: (bool value) {
                          themeProvider.toggleTheme(value);
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.orange),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const ZenvyroBrandingWidget(),
          ],
        ),
      ),
    );
  }
}
