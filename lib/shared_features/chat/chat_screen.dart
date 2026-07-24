import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String senderId, String senderEmail) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderEmail': senderEmail,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';
    final userEmail = authProvider.currentUser?.email ?? 'User';

    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.recipientName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId)
                  .collection('messages')
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
                    final isMe = senderId == userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          messageText,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
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
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () => _sendMessage(userId, userEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
