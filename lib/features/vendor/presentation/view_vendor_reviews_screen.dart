import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ViewVendorReviewsScreen extends StatelessWidget {
  const ViewVendorReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Reviews & Ratings')),
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

          final shopId = shopSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('shopId', isEqualTo: shopId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, reviewSnapshot) {
              if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No customer reviews found yet.'));
              }

              final reviews = reviewSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final data = reviews[index].data() as Map<String, dynamic>;
                  final customerEmail = data['customerEmail'] ?? 'Anonymous Customer';
                  final rating = (data['rating'] ?? 5.0).toDouble();
                  final comment = data['comment'] ?? 'No comment provided.';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                customerEmail,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                      (starIndex) => Icon(
                                    starIndex < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(comment, style: const TextStyle(color: Colors.black87)),
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
    );
  }
}