import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared_features/widgets/safe_image.dart';

class ManageVendorShopBannerScreen extends StatefulWidget {
  const ManageVendorShopBannerScreen({super.key});

  @override
  State<ManageVendorShopBannerScreen> createState() =>
      _ManageVendorShopBannerScreenState();
}

class _ManageVendorShopBannerScreenState
    extends State<ManageVendorShopBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bannerTitleController = TextEditingController();
  final _bannerImageUrlController = TextEditingController();
  final _bannerEventController = TextEditingController(); // NEW
  bool _isLoading = false;
  bool _isInitialized = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
          _bannerImageUrlController.clear();
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

  @override
  void dispose() {
    _bannerTitleController.dispose();
    _bannerImageUrlController.dispose();
    _bannerEventController.dispose();
    super.dispose();
  }

  Future<void> _updateBanner(String shopId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String bannerUrl = _bannerImageUrlController.text.trim();
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        bannerUrl = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
        'pendingBannerTitle': _bannerTitleController.text.trim(),
        'pendingBannerImageUrl': bannerUrl,
        'pendingBannerEvent': _bannerEventController.text.trim(),
        'bannerStatus': 'pending', // require admin approval
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop banner updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating banner: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Shop Banner')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No shop assigned to your account.'));
          }

          final shopDoc = snapshot.data!.docs.first;
          final shopId = shopDoc.id;
          final data = shopDoc.data() as Map<String, dynamic>;

          if (!_isInitialized) {
            _bannerTitleController.text = data['bannerTitle'] ?? '';
            _bannerImageUrlController.text = data['bannerImageUrl'] ?? '';
            _bannerEventController.text = data['bannerEvent'] ?? '';
            _isInitialized = true;
          }
          final bool isPending = data['bannerStatus'] == 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pending_actions, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your new banner is pending admin approval. The current approved banner will remain visible to customers until then.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_imageFile != null)
                    Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (data['bannerImageUrl'] != null &&
                      data['bannerImageUrl'].toString().isNotEmpty)
                    Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeImage(
                        imageUrl: data['bannerImageUrl'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  TextFormField(
                    controller: _bannerTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Promo Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bannerEventController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Event (e.g., Azadi Sale, Flash Sale)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image from Device'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('OR', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bannerImageUrlController,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => _updateBanner(shopId),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Banner For Approval',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
