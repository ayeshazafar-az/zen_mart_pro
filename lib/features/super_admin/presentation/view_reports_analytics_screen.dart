import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewReportsAnalyticsScreen extends StatelessWidget {
  const ViewReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Platform Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Users', 'users', Icons.people, Colors.blue),
                _buildStatCard('Total Shops', 'shops', Icons.store, Colors.orange),
                _buildStatCard('Total Products', 'products', Icons.shopping_bag, Colors.purple, isCollectionGroup: true),
                _buildStatCard('Total Orders', 'orders', Icons.receipt_long, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon, Color color, {bool isCollectionGroup = false}) {
    Stream<QuerySnapshot> stream = isCollectionGroup
        ? FirebaseFirestore.instance.collectionGroup(collection).snapshots()
        : FirebaseFirestore.instance.collection(collection).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 28),
                    Text(
                      count,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}