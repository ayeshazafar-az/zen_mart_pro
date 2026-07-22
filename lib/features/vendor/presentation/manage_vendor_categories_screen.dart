import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ManageVendorCategoriesScreen extends StatefulWidget {
  const ManageVendorCategoriesScreen({super.key});

  @override
  State<ManageVendorCategoriesScreen> createState() => _ManageVendorCategoriesScreenState();
}

class _ManageVendorCategoriesScreenState extends State<ManageVendorCategoriesScreen> {
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory(String shopId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final categoryName = _categoryController.text.trim();
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('categories')
          .add({
        'name': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _categoryController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    }
  }

  Future<void> _editCategory(String shopId, String categoryId, String currentName) async {
    final editController = TextEditingController(text: currentName);

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextFormField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true && editController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('categories')
          .doc(categoryId)
          .update({
        'name': editController.text.trim(),
      });
    }
    editController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
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
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No shop assigned to your vendor account yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final shopDocId = shopSnapshot.data!.docs.first.id;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add Category Form
                Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'New Category Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Enter category name' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _addCategory(shopDocId),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shop Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                // Categories List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('shops')
                        .doc(shopDocId)
                        .collection('categories')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, categorySnapshot) {
                      if (categorySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No categories added yet.'));
                      }

                      final categories = categorySnapshot.data!.docs;

                      return ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final data = categories[index].data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unnamed';
                          final docId = categories[index].id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editCategory(shopDocId, docId, name),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('shops')
                                          .doc(shopDocId)
                                          .collection('categories')
                                          .doc(docId)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}