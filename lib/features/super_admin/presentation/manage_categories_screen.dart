import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final categoryName = _categoryController.text.trim();
      await FirebaseFirestore.instance.collection('categories').add({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Padding(
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
                    onPressed: _addCategory,
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
                'Existing Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // Categories List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No categories found.'));
                  }

                  final categories = snapshot.data!.docs;

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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('categories')
                                  .doc(docId)
                                  .delete();
                            },
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
      ),
    );
  }
}