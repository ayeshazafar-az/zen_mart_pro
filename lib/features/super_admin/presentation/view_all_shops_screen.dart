import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllShopsScreen extends StatelessWidget {
  const ViewAllShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Platform Shops')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No shops found on the platform.'));
          }

          final shops = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final data = shops[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Shop';
              final address = data['address'] ?? 'No address';
              final phone = data['phone'] ?? 'N/A';
              final imageUrl = data['imageUrl'] ?? '';
              final docId = shops[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.store),
                  )
                      : const Icon(Icons.store, size: 40),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Address: $address\nPhone: $phone'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Shop'),
                          content: Text('Are you sure you want to delete $name?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('shops')
                            .doc(docId)
                            .delete();
                      }
                    },
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