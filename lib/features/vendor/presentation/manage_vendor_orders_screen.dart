import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/chat/chat_screen.dart';
import '../../../core/services/notification_service.dart';

class ManageVendorOrdersScreen extends StatelessWidget {
  const ManageVendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Receive & Manage Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!shopSnapshot.hasData || shopSnapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No shop assigned to your account.'));
          }

          final shopId = shopSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('shopId', isEqualTo: shopId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No orders received yet.'));
              }

              final orders = orderSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderDoc = orders[index];
                  final data = orderDoc.data() as Map<String, dynamic>;
                  final orderId = orderDoc.id;
                  final totalAmount = data['totalAmount']?.toString() ?? '0.00';
                  final status = data['status'] ?? 'Pending';
                  final customerEmail = data['customerEmail'] ?? 'Customer';
                  final customerId = data['customerId'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${orderId.substring(0, 8)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Chip(
                                label: Text(status.toUpperCase(),
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: _getStatusColor(status)
                                    .withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Customer: $customerEmail'),
                          Text('Total Amount: \$ $totalAmount'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'Pending') ...[
                                OutlinedButton(
                                  onPressed: () => _updateOrderStatus(
                                      orderId, 'Rejected', customerId),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _updateOrderStatus(
                                      orderId, 'Accepted', customerId),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Accept'),
                                ),
                              ] else ...[
                                DropdownButton<String>(
                                  value: [
                                    'Accepted',
                                    'Preparing',
                                    'Out for Delivery',
                                    'Delivered'
                                  ].contains(status)
                                      ? status
                                      : 'Accepted',
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Accepted',
                                        child: Text('Accepted')),
                                    DropdownMenuItem(
                                        value: 'Preparing',
                                        child: Text('Preparing')),
                                    DropdownMenuItem(
                                        value: 'Out for Delivery',
                                        child: Text('Out for Delivery')),
                                    DropdownMenuItem(
                                        value: 'Delivered',
                                        child: Text('Delivered')),
                                  ],
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      _updateOrderStatus(
                                          orderId, newStatus, customerId);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ([
                            'Pending',
                            'Accepted',
                            'Preparing',
                            'Out for Delivery'
                          ].contains(status))
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat),
                                label: const Text('Chat & Call Customer'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        orderId: orderId,
                                        recipientName:
                                            customerEmail.split('@')[0],
                                        chatChannel: 'vendor_messages',
                                        recipientPhone:
                                            data['phone'], // Customer's phone
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'preparing':
      case 'out for delivery':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateOrderStatus(
      String orderId, String status, String customerId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
    });

    // --- FCM TRIGGER: Notify Customer ---
    String title = "Order Update";
    String body = "Your order status is now: \$status";

    if (status == 'Accepted') body = "The vendor has accepted your order.";
    if (status == 'Rejected') {
      title = "Order Cancelled";
      body = "Unfortunately, the vendor rejected your order.";
    }
    if (status == 'Preparing') body = "The vendor is preparing your order.";

    try {
      await NotificationService().sendMockNotificationToUser(
        customerId,
        title,
        body,
      );
    } catch (e) {
      debugPrint('Failed to send vendor update notification: \$e');
    }
  }
}
