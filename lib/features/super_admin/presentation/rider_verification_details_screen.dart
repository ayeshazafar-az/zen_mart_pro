import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class RiderVerificationDetailsScreen extends StatelessWidget {
  final DocumentSnapshot riderDoc;

  const RiderVerificationDetailsScreen({super.key, required this.riderDoc});

  Widget _buildPhotoBlock(BuildContext context, String title, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 8),
        if (url != null && url.isNotEmpty)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(10),
                  child: InteractiveViewer(
                    child: url.startsWith('http')
                        ? Image.network(url, fit: BoxFit.contain)
                        : Image.memory(base64Decode(url), fit: BoxFit.contain),
                  ),
                ),
              );
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                image: DecorationImage(
                    image: url.startsWith('http')
                        ? NetworkImage(url) as ImageProvider
                        : MemoryImage(base64Decode(url)),
                    fit: BoxFit.cover),
              ),
              child: const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.zoom_in,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                ),
              ),
            ),
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Text('No image provided',
                    style: TextStyle(color: Colors.grey))),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = riderDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'N/A';
    final email = data['email'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final address = data['address'] ?? 'N/A';
    final city = data['city'] ?? 'N/A';
    final vehicleType = data['vehicleType'] ?? 'N/A';
    final bankName = data['bankName'] ?? 'N/A';
    final isApproved = data['isApproved'] ?? false;

    return Scaffold(
      appBar: AppBar(title: Text('Verify: $name')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isApproved
                        ? Colors.green.shade300
                        : Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(isApproved ? Icons.check_circle : Icons.pending,
                      color: isApproved ? Colors.green : Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    isApproved ? 'Rider is Approved' : 'Pending Verification',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isApproved
                            ? Colors.green.shade800
                            : Colors.orange.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.orange.shade100,
                backgroundImage: data['profileImageUrl'] != null &&
                        data['profileImageUrl'].isNotEmpty
                    ? (data['profileImageUrl'].toString().startsWith('http')
                        ? NetworkImage(data['profileImageUrl']) as ImageProvider
                        : MemoryImage(base64Decode(data['profileImageUrl'])))
                    : null,
                child: data['profileImageUrl'] == null ||
                        data['profileImageUrl'].isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.orange)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('Full Name', name),
            _buildInfoRow('Email', email),
            _buildInfoRow('Contact', phone),
            _buildInfoRow('City', city),
            _buildInfoRow('Address', address),
            _buildInfoRow('Bank Option', bankName),
            _buildInfoRow('Vehicle', vehicleType),
            const SizedBox(height: 24),
            const Text('Verification Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildPhotoBlock(context, 'Vehicle Image', data['vehicleImageUrl']),
            _buildPhotoBlock(
                context, 'Driving License', data['drivingLicenseUrl']),
            _buildPhotoBlock(context, 'CNIC Front', data['cnicFrontUrl']),
            _buildPhotoBlock(context, 'CNIC Back', data['cnicBackUrl']),
            _buildPhotoBlock(
                context, 'Payment Receipt', data['paymentReceiptUrl']),
            const SizedBox(height: 32),
            if (!isApproved)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection(AppConstants.usersCollection)
                            .doc(riderDoc.id)
                            .delete();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Reject & Delete'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection(AppConstants.usersCollection)
                            .doc(riderDoc.id)
                            .update({'isApproved': true});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Rider Approved!'),
                                  backgroundColor: Colors.green));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Approve Rider',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .doc(riderDoc.id)
                        .update({'isApproved': false});
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.block, color: Colors.orange),
                  label: const Text('Revoke Approval',
                      style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
