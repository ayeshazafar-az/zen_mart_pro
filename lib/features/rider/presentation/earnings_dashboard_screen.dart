import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class EarningsDashboardScreen extends StatelessWidget {
  const EarningsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final riderId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: riderId)
            .where('status', isEqualTo: 'Delivered')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double totalEarnings = 0.0;
          int totalDeliveries = 0;

          if (snapshot.hasData) {
            totalDeliveries = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              // A rider earns the static delivery fee per delivered order.
              // If an old order does not have deliveryFee, default to 0.0 or 50.0 based on fallback.
              final amount = (data['deliveryFee'] ?? 0.0) as num;
              totalEarnings += amount.toDouble();
            }
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Earnings Overview',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade800
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.greenAccent
                              : Colors.green.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'You earn 100% of the Delivery Charge attached to every completed order.',
                          style: TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Earnings',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('Rs. ${totalEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Deliveries',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('$totalDeliveries',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Payout Summary',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.account_balance, color: Colors.orange),
                    title: Text('Weekly Payout Status'),
                    subtitle: Text(
                        'Processed every Monday via Bank Transfer / Wallet'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
