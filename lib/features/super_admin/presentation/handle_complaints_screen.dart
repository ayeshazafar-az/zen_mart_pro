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

              Color statusColor =
                  status == 'Resolved' ? Colors.green : Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Complaint from $userEmail'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: $status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor)),
                              const SizedBox(height: 16),
                              const Text('Message:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(message),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          if (status != 'Resolved')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('complaints')
                                    .doc(docId)
                                    .update({'status': 'Resolved'});
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Mark Resolved',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          if (status != 'Unresolved')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('complaints')
                                    .doc(docId)
                                    .update({'status': 'Unresolved'});
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Mark Unresolved',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          if (status != 'Pending')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('complaints')
                                    .doc(docId)
                                    .update({'status': 'Pending'});
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Mark Pending',
                                  style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    );
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.report_problem),
                  ),
                  title: Text('From: $userEmail',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Complaint: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}\nStatus: $status',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    backgroundColor: status == 'Resolved'
                        ? Colors.green[50]
                        : (status == 'Pending'
                            ? Colors.orange[50]
                            : Colors.red[50]),
                    label: Text(status),
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
