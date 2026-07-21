import 'package:flutter/material.dart';

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.email, color: Colors.orange),
                      title: Text('Email Support'),
                      subtitle: Text('support@zenvyro.com'),
                    ),
                    const Divider(),
                    const ListTile(
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
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
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