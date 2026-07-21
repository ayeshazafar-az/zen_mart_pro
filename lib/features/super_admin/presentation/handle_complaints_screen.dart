import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HandleComplaintsScreen extends StatelessWidget {
  const HandleComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handle Complaints')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No complaints found.'));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final data = complaints[index].data() as Map<String, dynamic>;
              final docId = complaints[index].id;
              final userEmail = data['userEmail'] ?? 'Anonymous';
              final message = data['message'] ?? 'No message provided';
              final status = data['status'] ?? 'Open';

              Color statusColor = status == 'Resolved' ? Colors.green : Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.report_problem),
                  ),
                  title: Text('From: $userEmail', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Complaint: $message\nStatus: $status'),
                  isThreeLine: true,
                  trailing: status != 'Resolved'
                      ? ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('complaints')
                          .doc(docId)
                          .update({'status': 'Resolved'});
                    },
                    child: const Text('Resolve'),
                  )
                      : const Chip(
                    label: Text('Resolved', style: TextStyle(color: Colors.green)),
                    backgroundColor: Colors.green50,
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