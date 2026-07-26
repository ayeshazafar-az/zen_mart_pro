import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/services/notification_service.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'How can I track my order?',
              'You can track your order in real-time by going to Order History and tapping on your active order.',
            ),
            _buildFaqItem(
              'What payment methods are supported?',
              'We support Cash on Delivery, Credit/Debit Cards, and Online Wallets.',
            ),
            _buildFaqItem(
              'How do I cancel an order?',
              'Orders can be cancelled before the vendor accepts them via the order status page or by contacting support.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.orange),
                      title: Text('Email Support'),
                      subtitle: Text('support@zenvyro.com'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.orange),
                      title: Text('Helpline'),
                      subtitle: Text('+92 300 1234567'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComplaintDialog(context),
        icon: const Icon(Icons.report_problem),
        label: const Text('Submit a Complaint'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showComplaintDialog(BuildContext context) {
    final complaintController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('File a Complaint'),
          content: TextField(
            controller: complaintController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe your issue here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final message = complaintController.text.trim();
                if (message.isEmpty) return;

                Navigator.pop(context);

                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;

                await FirebaseFirestore.instance.collection('complaints').add({
                  'userId': user?.uid ?? 'unknown',
                  'userEmail': user?.email ?? 'Anonymous',
                  'message': message,
                  'status': 'Open',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Find Super Admins and Dispatch Notification
                try {
                  final adminQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Admin')
                      .get();

                  for (var adminDoc in adminQuery.docs) {
                    await NotificationService().sendMockNotificationToUser(
                      adminDoc.id,
                      "New Complaint Received \u{26A0}\u{FE0F}",
                      "From \${user?.email ?? 'Anonymous'}: \$message",
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to send admin notification: \$e');
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Complaint submitted successfully. Our team will review it.')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
