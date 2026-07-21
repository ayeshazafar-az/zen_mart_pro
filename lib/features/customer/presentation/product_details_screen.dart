import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = widget.productDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Product Name';
    final price = data['price']?.toString() ?? '0.00';
    final description = data['description'] ?? 'No description available for this product.';
    final imageUrl = data['imageUrl'] ?? '';
    final stock = data['stock'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 280,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              )
            else
              Container(
                height: 280,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$ $price',
                    style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
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
                        const Text('Quantity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _quantity < stock ? () => setState(() => _quantity++) : null,
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
            onPressed: () {
              // TODO: Implement Cart provider / Add to Cart logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $_quantity x $name to cart!')),
              );
            },
            child: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
          ),
        ),
      )
          : null,
    );
  }
}