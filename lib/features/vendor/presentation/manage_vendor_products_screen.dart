import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ManageVendorProductsScreen extends StatefulWidget {
  const ManageVendorProductsScreen({super.key});

  @override
  State<ManageVendorProductsScreen> createState() => _ManageVendorProductsScreenState();
}

class _ManageVendorProductsScreenState extends State<ManageVendorProductsScreen> {
  void _showProductDialog(String shopId, {DocumentSnapshot? productDoc}) {
    final isEditing = productDoc != null;
    final nameController = TextEditingController(text: isEditing ? productDoc['name'] : '');
    final priceController = TextEditingController(text: isEditing ? productDoc['price']?.toString() : '');
    final stockController = TextEditingController(text: isEditing ? productDoc['stock']?.toString() : '');
    final imageUrlController = TextEditingController(text: isEditing ? productDoc['imageUrl'] : '');
    final descriptionController = TextEditingController(text: isEditing ? productDoc['description'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final stock = int.tryParse(stockController.text.trim()) ?? 0;
              final imageUrl = imageUrlController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isEmpty) return;

              final productsRef = FirebaseFirestore.instance
                  .collection('shops')
                  .doc(shopId)
                  .collection('products');

              if (isEditing) {
                await productsRef.doc(productDoc.id).update({
                  'name': name,
                  'price': price,
                  'stock': stock,
                  'imageUrl': imageUrl,
                  'description': description,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              } else {
                await productsRef.add({
                  'name': name,
                  'price': price,
                  'stock': stock,
                  'imageUrl': imageUrl,
                  'description': description,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }

              if (mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products & Stock')),
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
            return const Center(child: Text('No shop assigned to your account.'));
          }

          final shopDocId = shopSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shops')
                .doc(shopDocId)
                .collection('products')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No products found.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showProductDialog(shopDocId),
                        child: const Text('Add First Product'),
                      ),
                    ],
                  ),
                );
              }

              final products = productSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final doc = products[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unnamed';
                  final price = data['price']?.toString() ?? '0.00';
                  final stock = data['stock']?.toString() ?? '0';
                  final imageUrl = data['imageUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                          : const Icon(Icons.shopping_bag),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Price: \$ $price | Stock: $stock'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductDialog(shopDocId, productDoc: doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.delete();
                            },
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
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
          final shopDocId = snapshot.data!.docs.first.id;
          return FloatingActionButton(
            onPressed: () => _showProductDialog(shopDocId),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}