import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllOrdersScreen extends StatelessWidget {
  const ViewAllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Platform Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found on the platform.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final totalAmount = data['totalAmount']?.toString() ?? '0.00';
              final status = data['status'] ?? 'Pending';
              final customerEmail = data['customerEmail'] ?? 'Unknown Customer';

              Color statusColor;
              switch (status.toLowerCase()) {
                case 'delivered':
                  statusColor = Colors.green;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long),
                  ),
                  title: Text('Order ID: ${orderId.substring(0, 8)}...',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Customer: $customerEmail\nTotal: \$ $totalAmount'),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}