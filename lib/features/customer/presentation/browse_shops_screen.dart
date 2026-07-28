import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_features/widgets/safe_image.dart';
import 'shop_products_screen.dart';

class BrowseShopsScreen extends StatelessWidget {
  const BrowseShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse All Shops')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No shops available at the moment.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final shops = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shopDoc = shops[index];
              final data = shopDoc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Shop';
              final address = data['address'] ?? 'No address provided';
              final phone = data['phone'] ?? 'No phone';
              final imageUrl = data['imageUrl'] ?? '';
              final bannerTitle = data['bannerTitle'] ?? '';
              final categoryIds = data['categoryIds'] as List<dynamic>? ??
                  [if (data['categoryId'] != null) data['categoryId']];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopProductsScreen(
                          shopId: shopDoc.id,
                          shopName: name,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            if (imageUrl.isEmpty) return;
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      child: SafeImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.contain,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height,
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: SafeImage(
                              imageUrl: imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (bannerTitle.isNotEmpty)
                              Text(
                                bannerTitle,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600),
                              ),
                            const SizedBox(height: 8),
                            if (categoryIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categoryIds.take(3).map((catId) {
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('categories')
                                          .doc(catId)
                                          .get(),
                                      builder: (context, catSnapshot) {
                                        String catName = '...';
                                        if (catSnapshot.hasData &&
                                            catSnapshot.data!.exists) {
                                          catName =
                                              catSnapshot.data!.get('name') ??
                                                  'Category';
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.blue
                                                        .withValues(alpha: 0.2)
                                                    : Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            catName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.blue.shade300
                                                  : Colors.blue.shade700,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                    child: Text(address,
                                        style: const TextStyle(
                                            color: Colors.grey))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(phone,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
