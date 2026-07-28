import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_features/widgets/safe_image.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final DocumentSnapshot productDoc;

  const ProductDetailsScreen({super.key, required this.productDoc});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid ?? '';

    final data = widget.productDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Product Name';
    final price = data['price']?.toString() ?? '0.00';
    final originalPrice = data['originalPrice']?.toString();
    final discount = data['discountPercentage'] ?? 0;
    final description =
        data['description'] ?? 'No description available for this product.';
    final imageUrl = data['imageUrl'] ?? '';
    final stock = data['stock'] ?? 0;
    final categoryId = data['categoryId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (userId.isNotEmpty)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('wishlist')
                  .doc(widget.productDoc.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final inWishlist = snapshot.hasData && snapshot.data!.exists;
                return IconButton(
                  icon: Icon(
                    inWishlist ? Icons.favorite : Icons.favorite_border,
                    color: inWishlist ? Colors.red : null,
                  ),
                  onPressed: () async {
                    final docRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('wishlist')
                        .doc(widget.productDoc.id);

                    if (inWishlist) {
                      await docRef.delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Removed from wishlist')));
                      }
                    } else {
                      final parsedShopId = data['shopId'] ??
                          widget.productDoc.reference.parent.parent?.id;
                      final savedData = Map<String, dynamic>.from(data);
                      if (parsedShopId != null) {
                        savedData['shopId'] = parsedShopId;
                      }
                      await docRef.set(savedData);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to wishlist')));
                      }
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              SafeImage(
                imageUrl: imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 280,
                color: Colors.grey[200],
                child: const Center(
                    child:
                        Icon(Icons.shopping_bag, size: 80, color: Colors.grey)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (discount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '-$discount% Special Discount',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        'Rs. $price',
                        style: TextStyle(
                            fontSize: 24,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade400
                                    : Colors.green.shade700,
                            fontWeight: FontWeight.w900),
                      ),
                      if (originalPrice != null && discount > 0) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Text(
                            'Rs. $originalPrice',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough),
                          ),
                        ),
                      ]
                    ],
                  ),
                  if (categoryId != null) ...[
                    const SizedBox(height: 8),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('shops')
                          .doc(widget.productDoc.reference.parent.parent?.id)
                          .collection('categories')
                          .doc(categoryId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final catName = snapshot.data!['name'] ?? 'Category';
                          return Chip(
                            label: Text(catName,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.shade100
                                        : Colors.blue.shade900)),
                            backgroundColor: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.blue.shade900.withValues(alpha: 0.3)
                                : Colors.blue.shade50,
                            side: BorderSide.none,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    stock > 0 ? 'In Stock ($stock available)' : 'Out of Stock',
                    style: TextStyle(
                      color: stock > 0 ? Colors.grey[700] : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  if (stock > 0) ...[
                    Row(
                      children: [
                        const Text('Quantity: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _quantity < stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: stock > 0
          ? Container(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final userId = authProvider.currentUser?.uid ?? '';
                    if (userId.isEmpty) return;

                    try {
                      // Get shopId from the product mapping or fallback to parent hierarchy
                      final productRef = widget.productDoc.reference;
                      final shopId =
                          data['shopId'] ?? productRef.parent.parent?.id ?? '';

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('cart')
                          .add({
                        'productId': widget.productDoc.id,
                        'shopId': shopId,
                        'name': name,
                        'price': data['price'] ?? 0.0,
                        'quantity': _quantity,
                        'imageUrl': imageUrl,
                        'addedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Added $_quantity x $name to cart!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding to cart: $e')),
                        );
                      }
                    }
                  },
                  child:
                      const Text('Add to Cart', style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }
}
