import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared_features/widgets/safe_image.dart';

class ManageShopBannersScreen extends StatefulWidget {
  const ManageShopBannersScreen({super.key});

  @override
  State<ManageShopBannersScreen> createState() =>
      _ManageShopBannersScreenState();
}

class _ManageShopBannersScreenState extends State<ManageShopBannersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _shopIdController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _shopIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image.')),
        );
      }
    }
  }

  Future<void> _addBanner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String bannerUrl = _imageUrlController.text.trim();
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        bannerUrl = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('shop_banners').add({
        'title': _titleController.text.trim(),
        'imageUrl': bannerUrl,
        'shopId': _shopIdController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _imageUrlController.clear();
      _shopIdController.clear();
      setState(() {
        _imageFile = null;
      });

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter banner title'
                        : null,
                  ),
                  if (_imageFile != null)
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image from Device'),
                  ),
                  const SizedBox(height: 12),
                  const Text('OR', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Image URL',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && _imageFile != null) {
                        setState(() {
                          _imageFile = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (_imageFile == null &&
                          (value == null || value.isEmpty)) {
                        return 'Provide an image from device or URL';
                      }
                      return null;
                    },
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
                      onPressed: _isLoading ? null : _addBanner,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Add Shop Banner'),
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
                    return const Center(
                        child: Text('No active banners found.'));
                  }

                  final banners = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final data =
                          banners[index].data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Banner';
                      final imageUrl = data['imageUrl'] ?? '';
                      final docId = banners[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: SafeImage(
                                        imageUrl: imageUrl, fit: BoxFit.cover),
                                  ),
                                )
                              : const Icon(Icons.image),
                          title: Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('Shop ID: ${data['shopId'] ?? "None"}'),
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
