import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/chat/chat_screen.dart';
import '../../../core/services/notification_service.dart';

class ManageVendorOrdersScreen extends StatefulWidget {
  const ManageVendorOrdersScreen({super.key});

  @override
  State<ManageVendorOrdersScreen> createState() =>
      _ManageVendorOrdersScreenState();
}

class _ManageVendorOrdersScreenState extends State<ManageVendorOrdersScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Pending',
    'Accepted',
    'Preparing',
    'Ready',
    'Out for Delivery',
    'Delivered',
    'Rejected/Cancelled',
  ];

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
          final shopData =
              shopSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          final shopLogoUrl = shopData['logoUrl'] as String? ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('shopId', isEqualTo: shopId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No orders received yet.'));
              }

              List<QueryDocumentSnapshot> orders =
                  orderSnapshot.data!.docs.toList();

              // Sort by date
              orders.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              // Filter by Selected Category
              if (_selectedCategory != 'All') {
                orders = orders.where((doc) {
                  final status = (doc.data() as Map<String, dynamic>)['status']
                          ?.toString() ??
                      'Pending';
                  if (_selectedCategory == 'Rejected/Cancelled') {
                    return status == 'Rejected' || status == 'Cancelled';
                  }
                  return status == _selectedCategory;
                }).toList();
              }

              return Column(children: [
                // Categories Row
                SizedBox(
                    height: 60,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                  category == 'Pending'
                                      ? 'New Orders'
                                      : category,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : Colors.black87),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: Colors.orange,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                            ),
                          );
                        })),
                // Orders List
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text('No orders in this category.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final orderDoc = orders[index];
                            final data =
                                orderDoc.data() as Map<String, dynamic>;
                            final orderId = orderDoc.id;
                            final totalAmount =
                                data['totalAmount']?.toString() ?? '0.00';
                            final subtotal =
                                data['subtotal']?.toString() ?? totalAmount;
                            final status = data['status'] ?? 'Pending';
                            final customerEmail =
                                data['customerEmail'] ?? 'Customer';
                            final customerId = data['customerId'] ?? '';
                            final paymentMethod =
                                data['paymentMethod'] ?? 'Unknown';
                            final shippingAddress = data['shippingAddress'] ??
                                'No address provided';
                            final phone = data['phone'] ?? 'No phone provided';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          orderId.length > 8
                                              ? 'Order #${orderId.substring(0, 8)}'
                                              : 'Order #$orderId',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Chip(
                                          label: Text(status.toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          backgroundColor:
                                              _getStatusColor(status)
                                                  .withValues(alpha: 0.1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(customerId)
                                          .get(),
                                      builder: (context, userSnapshot) {
                                        String displayName = customerEmail;
                                        String imageUrl = '';
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data != null &&
                                            userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!
                                              .data() as Map<String, dynamic>?;
                                          if (userData != null) {
                                            if (userData.containsKey('name')) {
                                              displayName = userData['name'];
                                            }
                                            if (userData.containsKey(
                                                'profileImageUrl')) {
                                              imageUrl =
                                                  userData['profileImageUrl'];
                                            }
                                          }
                                        }
                                        return Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors
                                                  .orangeAccent
                                                  .withValues(alpha: 0.3),
                                              backgroundImage:
                                                  imageUrl.isNotEmpty
                                                      ? NetworkImage(imageUrl)
                                                      : null,
                                              child: imageUrl.isEmpty
                                                  ? const Icon(Icons.person,
                                                      size: 20,
                                                      color: Colors.orange)
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                  'Customer: $displayName',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.payment,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Method: $paymentMethod',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.account_balance_wallet,
                                              size: 20,
                                              color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Shop Earnings: Rs. $subtotal',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Delivery Details',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.redAccent),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(shippingAddress,
                                                style: const TextStyle(
                                                    fontSize: 13))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 16, color: Colors.blueAccent),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(phone,
                                                style: const TextStyle(
                                                    fontSize: 13))),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Order Items',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 8),
                                    if (data['items'] != null &&
                                        (data['items'] as List).isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          children: ((data['items'] as List)
                                              .map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${item["quantity"]}x ${item["name"]}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rs. ${item["price"]}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })).toList(),
                                        ),
                                      )
                                    else
                                      const Text('No items specified',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'Pending') ...[
                                          OutlinedButton(
                                            onPressed: () => _updateOrderStatus(
                                                orderId,
                                                'Rejected',
                                                customerId),
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Reject'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _updateOrderStatus(
                                                orderId,
                                                'Accepted',
                                                customerId),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green),
                                            child: const Text('Accept'),
                                          ),
                                        ] else ...[
                                          DropdownButton<String>(
                                            value: [
                                              'Accepted',
                                              'Preparing',
                                              'Ready',
                                              'Out for Delivery',
                                              'Delivered'
                                            ].contains(status)
                                                ? status
                                                : 'Accepted',
                                            items: [
                                              'Accepted',
                                              'Preparing',
                                              'Ready',
                                              'Out for Delivery',
                                              'Delivered'
                                            ]
                                                .where((s) {
                                                  final progression = [
                                                    'Accepted',
                                                    'Preparing',
                                                    'Ready',
                                                    'Out for Delivery',
                                                    'Delivered'
                                                  ];
                                                  final currentIndex =
                                                      progression
                                                          .indexOf(status);
                                                  final itemIndex =
                                                      progression.indexOf(s);
                                                  return itemIndex >=
                                                      (currentIndex == -1
                                                          ? 0
                                                          : currentIndex);
                                                })
                                                .map((s) => DropdownMenuItem(
                                                    value: s, child: Text(s)))
                                                .toList(),
                                            onChanged: (newStatus) {
                                              if (newStatus != null) {
                                                _updateOrderStatus(orderId,
                                                    newStatus, customerId);
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
                                      'Ready',
                                      'Out for Delivery'
                                    ].contains(status))
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.chat),
                                          label: const Text(
                                              'Chat & Call Customer'),
                                          onPressed: () async {
                                            String realCustomerName =
                                                customerEmail.split('@')[0];
                                            try {
                                              if (customerId.isNotEmpty) {
                                                final doc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc(customerId)
                                                        .get();
                                                if (doc.exists) {
                                                  realCustomerName =
                                                      doc.data()?['name'] ??
                                                          realCustomerName;
                                                }
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                  'Error fetching customer name: $e');
                                            }

                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatScreen(
                                                    orderId: orderId,
                                                    recipientName:
                                                        realCustomerName,
                                                    chatChannel:
                                                        'vendor_messages',
                                                    recipientPhone:
                                                        data['phone'],
                                                    recipientId: customerId,
                                                    shopLogoUrl:
                                                        shopLogoUrl.isNotEmpty
                                                            ? shopLogoUrl
                                                            : null,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ]);
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
      case 'ready':
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
    String body = "Your order status is now: $status";

    if (status == 'Accepted') body = "The vendor has accepted your order.";
    if (status == 'Rejected') {
      title = "Order Cancelled";
      body = "Unfortunately, the vendor rejected your order.";
    }
    if (status == 'Preparing') body = "The vendor is preparing your order.";
    if (status == 'Ready') body = "Your order is ready.";

    try {
      await NotificationService().sendMockNotificationToUser(
        customerId,
        title,
        body,
      );
    } catch (e) {
      debugPrint('Failed to send vendor update notification: $e');
    }
  }
}
