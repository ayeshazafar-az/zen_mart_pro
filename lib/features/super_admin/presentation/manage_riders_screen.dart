import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'rider_verification_details_screen.dart';

class ManageRidersScreen extends StatelessWidget {
  const ManageRidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approved Riders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: 'rider')
            .where('isApproved', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No riders found.'));
          }

          final riders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final data = riders[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Rider';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? 'N/A';
              final imageUrl = data['profileImageUrl'] ?? '';

              final isApproved = data['isApproved'] ?? false;

              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isApproved
                    ? (isDark ? Colors.grey[850] : Colors.white)
                    : (isDark ? Colors.orange[900] : Colors.orange.shade50),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiderVerificationDetailsScreen(
                            riderDoc: riders[index]),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.delivery_dining)
                        : null,
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Email: $email\nPhone: $phone\nStatus: ${isApproved ? "Approved" : "Pending Verification"}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isApproved)
                        const Icon(Icons.info_outline, color: Colors.orange),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Rider'),
                              content: Text(
                                  'Are you sure you want to delete $name?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection(AppConstants.usersCollection)
                                .doc(riders[index].id)
                                .delete();
                          }
                        },
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
