import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_features/widgets/safe_image.dart';
import 'product_details_screen.dart';

class ShopProductsScreen extends StatelessWidget {
  final String shopId;
  final String shopName;

  const ShopProductsScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shopName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('categories')
            .snapshots(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = categorySnapshot.hasData
              ? categorySnapshot.data!.docs
              : <QueryDocumentSnapshot>[];

          // Map for quick Category Name lookup
          final categoryMap = <String, String>{};
          for (var doc in categories) {
            final data = doc.data() as Map<String, dynamic>;
            categoryMap[doc.id] = data['name'] ?? 'Unnamed Category';
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shops')
                .doc(shopId)
                .collection('products')
                .snapshots(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!productSnapshot.hasData ||
                  productSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No products available in this shop yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final products = productSnapshot.data!.docs;

              // Group products by categoryId
              final groupedProducts = <String, List<QueryDocumentSnapshot>>{};
              for (var product in products) {
                final data = product.data() as Map<String, dynamic>;
                final catId = data['categoryId'] ?? 'uncategorized';

                if (!groupedProducts.containsKey(catId)) {
                  groupedProducts[catId] = [];
                }
                groupedProducts[catId]!.add(product);
              }

              // Build the sectioned list
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                itemCount: groupedProducts.keys.length,
                itemBuilder: (context, index) {
                  final catId = groupedProducts.keys.elementAt(index);
                  final categoryName = categoryMap[catId] ??
                      (catId == 'uncategorized' ? 'Uncategorized' : 'Other');
                  final categoryProducts = groupedProducts[catId]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      // Grid of Products for this Category
                      GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: categoryProducts.length,
                        itemBuilder: (context, pIndex) {
                          final productDoc = categoryProducts[pIndex];
                          final data =
                              productDoc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unnamed Product';
                          final price = data['price']?.toString() ?? '0.00';
                          final imageUrl = data['imageUrl'] ?? '';
                          final stock = data['stock'] ?? 0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(
                                        productDoc: productDoc),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: imageUrl.isNotEmpty
                                          ? SafeImage(
                                              imageUrl: imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons.shopping_bag,
                                                  size: 40,
                                                  color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs. $price',
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          stock > 0
                                              ? 'In Stock ($stock)'
                                              : 'Out of Stock',
                                          style: TextStyle(
                                            color: stock > 0
                                                ? Colors.grey
                                                : Colors.red,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16), // space between categories
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
