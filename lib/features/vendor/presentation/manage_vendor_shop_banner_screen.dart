import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ManageVendorShopBannerScreen extends StatefulWidget {
  const ManageVendorShopBannerScreen({super.key});

  @override
  State<ManageVendorShopBannerScreen> createState() => _ManageVendorShopBannerScreenState();
}

class _ManageVendorShopBannerScreenState extends State<ManageVendorShopBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bannerTitleController = TextEditingController();
  final _bannerImageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _bannerTitleController.dispose();
    _bannerImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateBanner(String shopId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
        'bannerTitle': _bannerTitleController.text.trim(),
        'bannerImageUrl': _bannerImageUrlController.text.trim(),
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
    final userId = authProvider.currentUser?.id ?? authProvider.currentUser?.uid ?? '';

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
            return const Center(child: Text('No shop assigned to your account.'));
          }

          final shopDoc = snapshot.data!.docs.first;
          final shopId = shopDoc.id;
          final data = shopDoc.data() as Map<String, dynamic>;

          if (!_isInitialized) {
            _bannerTitleController.text = data['bannerTitle'] ?? '';
            _bannerImageUrlController.text = data['bannerImageUrl'] ?? '';
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (data['bannerImageUrl'] != null && data['bannerImageUrl'].toString().isNotEmpty)
                    Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(data['bannerImageUrl']),
                          fit: BoxFit.cover,
                        ),
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
                    controller: _bannerImageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Image URL',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Enter banner image URL' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateBanner(shopId),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Banner', style: TextStyle(fontSize: 16)),
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