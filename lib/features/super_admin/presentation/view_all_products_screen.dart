import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllProductsScreen extends StatelessWidget {
  const ViewAllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Platform Products')),
      body: StreamBuilder<QuerySnapshot>(
        // Using collectionGroup to fetch products across all shops or a global products collection
        stream: FirebaseFirestore.instance.collectionGroup('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found on the platform.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Product';
              final price = data['price']?.toString() ?? '0.00';
              final imageUrl = data['imageUrl'] ?? '';
              final docId = products[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shopping_bag),
                  )
                      : const Icon(Icons.shopping_bag, size: 40),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Price: \$ $price'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Product'),
                          content: Text('Are you sure you want to delete $name?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await products[index].reference.delete();
                      }
                    },
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