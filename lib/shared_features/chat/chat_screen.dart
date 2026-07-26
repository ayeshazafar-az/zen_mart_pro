import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../core/services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String recipientName;
  final String recipientId;
  final String chatChannel; // e.g., 'vendor_messages' or 'rider_messages'
  final String? recipientPhone; // For Calling

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.recipientName,
    required this.recipientId,
    required this.chatChannel,
    this.recipientPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage(String senderId, String senderEmail) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final imageUrl = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection(widget.chatChannel)
          .add({
        'senderId': senderId,
        'senderEmail': senderEmail,
        'message': '', // Empty text message
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.recipientId.isNotEmpty) {
        await NotificationService().sendMockNotificationToUser(
          widget.recipientId,
          "New Photo from \$senderEmail",
          "[\u{1F4F7} Image]",
        );
      }
    } catch (e) {
      debugPrint('Failed to send image: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _sendMessage(String senderId, String senderEmail) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection(widget.chatChannel)
        .add({
      'senderId': senderId,
      'senderEmail': senderEmail,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      if (widget.recipientId.isNotEmpty) {
        await NotificationService().sendMockNotificationToUser(
          widget.recipientId,
          "New Message from \$senderEmail",
          text,
        );
      }
    } catch (e) {
      debugPrint('Failed to send chat notification: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';
    final userEmail = authProvider.currentUser?.email ?? 'User';

    return Scaffold(
      backgroundColor:
          const Color(0xFFE5DDD5), // WhatsApp chat background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // WhatsApp brand color
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.recipientName,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.recipientPhone != null &&
              widget.recipientPhone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              tooltip: 'Voice Call',
              onPressed: () => _makePhoneCall(widget.recipientPhone!),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId)
                  .collection(widget.chatChannel)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No messages yet. Say hello!'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final senderId = data['senderId'] ?? '';
                    final messageText = data['message'] ?? '';
                    final imageUrl = data['imageUrl'] ?? '';
                    final isMe = senderId == userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 8, left: 16, right: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color:
                                isMe ? const Color(0xFFDCF8C6) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMe
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 1,
                                  offset: Offset(0, 1))
                            ]),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 150,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox(
                                        height: 150,
                                        width: 150,
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (messageText.isNotEmpty)
                              Text(
                                messageText,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.photo_camera,
                              color: Colors.grey),
                          onPressed: () => _pickAndSendImage(userId, userEmail),
                        ),
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isUploadingImage
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child:
                            CircularProgressIndicator(color: Color(0xFF075E54)),
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF075E54),
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                          onPressed: () => _sendMessage(userId, userEmail),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
