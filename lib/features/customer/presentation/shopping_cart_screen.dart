import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import 'checkout_screen.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
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
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!.docs;
          double subtotal = 0.0;

          for (var doc in cartItems) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] ?? 0.0) as num;
            final quantity = (data['quantity'] ?? 1) as num;
            subtotal += price * quantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final doc = cartItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Product';
                    final price = data['price']?.toString() ?? '0.00';
                    final quantity = data['quantity'] ?? 1;
                    final imageUrl = data['imageUrl'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image))
                            : const Icon(Icons.shopping_bag),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Price: \$ $price | Qty: $quantity'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await doc.reference.delete();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text('\$ ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                cartItems: cartItems,
                                subtotal: subtotal,
                              ),
                            ),
                          );
                        },
                        child: const Text('Proceed to Checkout',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
