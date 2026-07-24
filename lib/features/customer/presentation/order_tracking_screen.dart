import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared_features/chat/chat_screen.dart';
import 'submit_review_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Your Order')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Order not found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final totalAmount = data['totalAmount']?.toString() ?? '0.00';
          final shippingAddress = data['shippingAddress'] ?? 'No address';
          final paymentMethod = data['paymentMethod'] ?? 'Cash on Delivery';
          final customerEmail = data['customerEmail'] ?? 'Customer';
          final shopId = data['shopId'] ?? '';
          final riderId = data['riderId'];
          final items = data['items'] as List<dynamic>? ?? [];

          final statusSteps = [
            'Pending',
            'Accepted',
            'Preparing',
            'Out for Delivery',
            'Delivered',
          ];

          int currentStep = statusSteps.indexOf(status);
          if (currentStep < 0) {
            // Handle rejected/cancelled
            currentStep = 0;
          }

          final bool isRejected = status == 'Rejected' || status == 'Cancelled';
          final bool isDelivered = status == 'Delivered';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderId.substring(0, 8)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: \$ $totalAmount',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _getStatusColor(status),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Stepper
                if (isRejected) ...[
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'This order has been $status by the vendor.',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Order Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Stepper(
                    currentStep: currentStep,
                    controlsBuilder: (context, details) =>
                        const SizedBox.shrink(),
                    physics: const NeverScrollableScrollPhysics(),
                    steps: statusSteps.map((step) {
                      final stepIndex = statusSteps.indexOf(step);
                      StepState state;
                      if (stepIndex < currentStep) {
                        state = StepState.complete;
                      } else if (stepIndex == currentStep) {
                        state = StepState.editing;
                      } else {
                        state = StepState.indexed;
                      }

                      return Step(
                        title: Text(step),
                        subtitle: stepIndex == currentStep
                            ? const Text('Current Status')
                            : null,
                        content: const SizedBox.shrink(),
                        isActive: stepIndex <= currentStep,
                        state: state,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Order Details
                const Text(
                  'Order Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            Icons.location_on, 'Address', shippingAddress),
                        const Divider(),
                        _buildDetailRow(
                            Icons.payment, 'Payment', paymentMethod),
                        const Divider(),
                        _buildDetailRow(Icons.email, 'Customer', customerEmail),
                        if (riderId != null &&
                            riderId.toString().isNotEmpty) ...[
                          const Divider(),
                          _buildDetailRow(
                              Icons.delivery_dining, 'Rider Assigned', 'Yes'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items List
                if (items.isNotEmpty) ...[
                  const Text(
                    'Items Ordered',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final itemData = item as Map<String, dynamic>;
                    final itemName = itemData['name'] ?? 'Product';
                    final itemPrice = itemData['price']?.toString() ?? '0.00';
                    final itemQty = itemData['quantity'] ?? 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag,
                            color: Colors.orange),
                        title: Text(itemName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Qty: $itemQty'),
                        trailing: Text('\$ $itemPrice',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                if (status == 'Pending') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Order?'),
                            content: const Text(
                                'Are you sure you want to cancel this order?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('No')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Yes, Cancel',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .update({'status': 'Cancelled'});
                        }
                      },
                      child: const Text('Cancel Order',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],

                // Chat with Rider button
                if (riderId != null &&
                    riderId.toString().isNotEmpty &&
                    !isDelivered &&
                    !isRejected) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat with Rider',
                          style: TextStyle(fontSize: 16)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              orderId: orderId,
                              recipientName: 'Rider',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Leave a Review button
                if (isDelivered) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      label: const Text('Leave a Review',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitReviewScreen(
                              shopId: shopId,
                              orderId: orderId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Back to Home',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'out for delivery':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
