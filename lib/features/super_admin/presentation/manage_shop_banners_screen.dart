import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageShopBannersScreen extends StatefulWidget {
  const ManageShopBannersScreen({super.key});

  @override
  State<ManageShopBannersScreen> createState() => _ManageShopBannersScreenState();
}

class _ManageShopBannersScreenState extends State<ManageShopBannersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _shopIdController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _shopIdController.dispose();
    super.dispose();
  }

  Future<void> _addBanner() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('shop_banners').add({
        'title': _titleController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'shopId': _shopIdController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _imageUrlController.clear();
      _shopIdController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop banner added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding banner: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Shop Banners')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Banner Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Title / Promo Text',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Enter banner title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Image URL',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Enter image URL' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shopIdController,
                    decoration: const InputDecoration(
                      labelText: 'Linked Shop ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addBanner,
                      child: const Text('Add Shop Banner'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Active Banners',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // Banners List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('shop_banners')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No active banners found.'));
                  }

                  final banners = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final data = banners[index].data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Banner';
                      final imageUrl = data['imageUrl'] ?? '';
                      final docId = banners[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                          )
                              : const Icon(Icons.image),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Shop ID: ${data['shopId'] ?? "None"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('shop_banners')
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