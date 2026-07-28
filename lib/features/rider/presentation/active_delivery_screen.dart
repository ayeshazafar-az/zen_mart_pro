import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/chat/chat_screen.dart';
import '../../../core/services/notification_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Start streaming position
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters changed
      ),
    ).listen((Position position) {
      _updateActiveOrdersLocation(position.latitude, position.longitude);
    });
  }

  Future<void> _updateActiveOrdersLocation(double lat, double lng) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final riderId = authProvider.currentUser?.uid ?? '';
    if (riderId.isEmpty) return;

    try {
      final activeOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('status', isEqualTo: 'Out for Delivery')
          .get();

      for (var doc in activeOrders.docs) {
        await doc.reference.update({
          'currentLatitude': lat,
          'currentLongitude': lng,
        });
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final riderId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: riderId)
            .where('status', isEqualTo: 'Out for Delivery')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bike, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active deliveries in progress.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;
              final orderId = orderDoc.id;
              final totalAmount = data['totalAmount']?.toString() ?? '0.00';
              final address = data['shippingAddress'] ?? 'No address';
              final customerEmail = data['customerEmail'] ?? 'Customer';
              final phone = data['phone'] ?? 'N/A';

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
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: data['customerId'] != null
                                  ? FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(data['customerId'])
                                      .snapshots()
                                  : null,
                              builder: (context, userSnapshot) {
                                String imageUrl = '';
                                if (userSnapshot.hasData &&
                                    userSnapshot.data!.exists) {
                                  final uData = userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                                  imageUrl = uData['profileImageUrl'] ?? '';
                                }
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Colors.blueAccent.withOpacity(0.2),
                                      backgroundImage: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: imageUrl.isEmpty
                                          ? const Icon(Icons.person,
                                              color: Colors.blue)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Order #${(orderId.length > 8 ? orderId.substring(0, 8) : orderId)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                              overflow: TextOverflow.ellipsis),
                                          Text('Customer: $customerEmail',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey),
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Chip(
                              label: Text('OUT FOR DELIVERY',
                                  style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.blueAccent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Phone: $phone'),
                      Text('Address: $address'),
                      Text('Payout: Rs. $totalAmount',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () async {
                            await orderDoc.reference.update({
                              'status': 'Delivered',
                            });

                            // --- FCM TRIGGER: Notify Customer ---
                            try {
                              final customerId = data['customerId'] ?? '';
                              if (customerId.isNotEmpty) {
                                await NotificationService()
                                    .sendMockNotificationToUser(
                                  customerId,
                                  "Order Delivered! \u{1F389}",
                                  "Your order has been delivered successfully. Enjoy!",
                                );
                              }
                            } catch (e) {
                              debugPrint('Failed to notify customer: \$e');
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order marked as Delivered!')),
                              );
                            }
                          },
                          child: const Text('Mark as Delivered',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat & Call Customer'),
                          onPressed: () async {
                            String realCustomerName =
                                customerEmail.split('@')[0];
                            try {
                              final cId = data['customerId'] ?? '';
                              if (cId.isNotEmpty) {
                                final doc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(cId)
                                    .get();
                                if (doc.exists) {
                                  realCustomerName =
                                      doc.data()?['name'] ?? realCustomerName;
                                }
                              }
                            } catch (e) {}

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    orderId: orderId,
                                    recipientName: realCustomerName,
                                    chatChannel: 'rider_messages',
                                    recipientPhone: phone,
                                    recipientId: data['customerId'] ?? '',
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
          );
        },
      ),
    );
  }
}
