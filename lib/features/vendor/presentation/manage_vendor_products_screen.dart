import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_features/widgets/safe_image.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class ManageVendorProductsScreen extends StatefulWidget {
  const ManageVendorProductsScreen({super.key});

  @override
  State<ManageVendorProductsScreen> createState() =>
      _ManageVendorProductsScreenState();
}

class _ManageVendorProductsScreenState
    extends State<ManageVendorProductsScreen> {
  void _showProductDialog(String shopId, List<dynamic> globalCategoryIds,
      {DocumentSnapshot? productDoc}) {
    final isEditing = productDoc != null;
    final nameController =
        TextEditingController(text: isEditing ? productDoc['name'] : '');
    final priceController = TextEditingController(
        text: isEditing
            ? (productDoc.data() as Map<String, dynamic>)
                    .containsKey('originalPrice')
                ? productDoc['originalPrice']?.toString()
                : productDoc['price']?.toString()
            : '');
    final discountController = TextEditingController(
        text: isEditing
            ? (productDoc.data() as Map<String, dynamic>)
                    .containsKey('discountPercentage')
                ? productDoc['discountPercentage']?.toString()
                : '0'
            : '');
    final stockController = TextEditingController(
        text: isEditing ? productDoc['stock']?.toString() : '');
    final descriptionController =
        TextEditingController(text: isEditing ? productDoc['description'] : '');

    String? dialogBase64Image = isEditing ? productDoc['imageUrl'] : null;

    String? selectedCategoryId = isEditing ? productDoc['categoryId'] : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Product' : 'Add Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                        maxWidth: 800,
                        maxHeight: 800,
                      );
                      if (pickedFile != null) {
                        final bytes = await File(pickedFile.path).readAsBytes();
                        setStateBuilder(() {
                          dialogBase64Image = base64Encode(bytes);
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid),
                      ),
                      child: dialogBase64Image != null &&
                              dialogBase64Image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SafeImage(
                                  imageUrl: dialogBase64Image!,
                                  fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 30, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Upload Product Image',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: () async {
                      final List<Map<String, dynamic>> combined = [];
                      // Fetch all global
                      final globalSnap = await FirebaseFirestore.instance
                          .collection(AppConstants.categoriesCollection)
                          .get();
                      for (var doc in globalSnap.docs) {
                        if (globalCategoryIds.contains(doc.id)) {
                          final data = doc.data();
                          combined.add({
                            'id': doc.id,
                            'name': '${data['name']} (Global)',
                          });
                        }
                      }
                      // Fetch local
                      final localSnap = await FirebaseFirestore.instance
                          .collection('shops')
                          .doc(shopId)
                          .collection('categories')
                          .get();
                      for (var doc in localSnap.docs) {
                        final data = doc.data();
                        combined.add({
                          'id': doc.id,
                          'name': '${data['name']}',
                        });
                      }
                      return combined;
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No categories available for your shop.',
                              style: TextStyle(color: Colors.red)),
                        );
                      }
                      final categories = snapshot.data!;
                      // Ensure selectedCategoryId exists in the options
                      if (selectedCategoryId != null &&
                          !categories
                              .any((cat) => cat['id'] == selectedCategoryId)) {
                        selectedCategoryId = null;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedCategoryId,
                            hint: const Text('Select a Category'),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['id'],
                                child: Text(cat['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateBuilder(() {
                                selectedCategoryId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Original Price (Rs.)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage (%) - Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
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
                  final originalPrice =
                      double.tryParse(priceController.text.trim()) ?? 0.0;
                  final discountPercentage =
                      int.tryParse(discountController.text.trim()) ?? 0;
                  // Dynamic final price calculation
                  final finalPrice = discountPercentage > 0
                      ? originalPrice -
                          (originalPrice * (discountPercentage / 100))
                      : originalPrice;

                  final stock = int.tryParse(stockController.text.trim()) ?? 0;
                  final imageUrl = dialogBase64Image ?? '';
                  final description = descriptionController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter a product name.')));
                    return;
                  }
                  if (selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please select a category.')));
                    return;
                  }

                  final productsRef = FirebaseFirestore.instance
                      .collection('shops')
                      .doc(shopId)
                      .collection('products');

                  if (isEditing) {
                    await productsRef.doc(productDoc.id).update({
                      'name': name,
                      'price':
                          finalPrice, // Checkout still reads 'price' correctly
                      'originalPrice': originalPrice,
                      'discountPercentage': discountPercentage,
                      'stock': stock,
                      'imageUrl': imageUrl,
                      'description': description,
                      'categoryId': selectedCategoryId,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await productsRef.add({
                      'name': name,
                      'price': finalPrice,
                      'originalPrice': originalPrice,
                      'discountPercentage': discountPercentage,
                      'stock': stock,
                      'imageUrl': imageUrl,
                      'description': description,
                      'categoryId': selectedCategoryId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }

                  if (mounted) Navigator.pop(context);
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
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
            return const Center(
                child: Text('No shop assigned to your account.'));
          }

          final shopDoc = shopSnapshot.data!.docs.first;
          final shopDocId = shopDoc.id;
          final shopData = shopDoc.data() as Map<String, dynamic>;
          final globalCategoryIds = shopData['categoryIds'] as List<dynamic>? ??
              [if (shopData['categoryId'] != null) shopData['categoryId']];

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

              if (!productSnapshot.hasData ||
                  productSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No products found.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            _showProductDialog(shopDocId, globalCategoryIds),
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
                  final categoryId = data['categoryId'];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SafeImage(
                                  imageUrl: imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.shopping_bag,
                                color: Colors.grey),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Price: Rs. $price | Stock: $stock',
                              style: TextStyle(color: Colors.grey.shade700)),
                          if (categoryId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection(AppConstants.categoriesCollection)
                                  .doc(categoryId)
                                  .get(),
                              builder: (context, catSnapshot) {
                                if (catSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Loading category...',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey));
                                }
                                if (catSnapshot.hasData &&
                                    catSnapshot.data!.exists) {
                                  final catData = catSnapshot.data!.data()
                                      as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.deepOrange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color:
                                                  Colors.deepOrange.shade200)),
                                      child: Text(
                                        catData['name'] ?? 'Unnamed',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange.shade700,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  color: Colors.blue.shade700, size: 20),
                              onPressed: () => _showProductDialog(
                                  shopDocId, globalCategoryIds,
                                  productDoc: doc),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.red.shade700, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: Text(
                                        'Are you sure you want to delete "$name"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.delete();
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
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          final shopDocId = snapshot.data!.docs.first.id;
          return FloatingActionButton.extended(
            onPressed: () => _showProductDialog(
                shopDocId,
                snapshot.data!.docs.first.data() != null
                    ? (snapshot.data!.docs.first.data()
                                as Map<String, dynamic>)['categoryIds']
                            as List<dynamic>? ??
                        [
                          if ((snapshot.data!.docs.first.data()
                                  as Map<String, dynamic>)['categoryId'] !=
                              null)
                            (snapshot.data!.docs.first.data()
                                as Map<String, dynamic>)['categoryId']
                        ]
                    : []),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }
}
