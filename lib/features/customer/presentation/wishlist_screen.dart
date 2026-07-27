import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../shared_features/widgets/safe_image.dart';
import '../../auth/presentation/auth_provider.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Your wishlist is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final wishlistItems = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final item = wishlistItems[index];
              final data = item.data() as Map<String, dynamic>;

              final discount = data['discountPercentage'] ?? 0;
              final originalPrice = data['originalPrice']?.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SafeImage(
                      imageUrl: data['imageUrl'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(data['name'] ?? 'Unknown Product',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Text('Rs. ${data['price']?.toString() ?? '0.00'}',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade400
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold)),
                      if (originalPrice != null && discount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Rs. $originalPrice',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ]
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.orange),
                        onPressed: () async {
                          final shopId = data['shopId'] ??
                              item.reference.parent.parent?.id ??
                              '';
                          if (shopId.isEmpty) return;

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('cart')
                                .add({
                              'productId': item.id,
                              'shopId': shopId,
                              'name': data['name'],
                              'price': data['price'] ?? 0.0,
                              'quantity': 1,
                              'imageUrl': data['imageUrl'] ?? '',
                              'addedAt': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Added ${data['name']} to cart!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error adding to cart: $e')),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await item.reference.delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Removed from wishlist')));
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to product details but require a DocumentReference for the actual product if possible.
                    // For the sake of simplicity, we pass minimal mocked structure if product lookup varies.
                    // Since product details expects a DocumentSnapshot, and we have a copy in wishlist, we can pass this doc.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(productDoc: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
