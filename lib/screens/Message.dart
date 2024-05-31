import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedUser;

class MessageScreen extends StatefulWidget {
  final String receiver;
  final String currentuser;

  const MessageScreen({required this.receiver, required this.currentuser});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController messagetextController = TextEditingController();
  String message = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    loggedUser = _auth.currentUser;
    print(loggedUser!.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                const SizedBox(width: 2),
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                      "https://plus.unsplash.com/premium_photo-1673866484792-c5a36a6c025e?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D"
                  ),
                  maxRadius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.receiver,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: MessageStream(currentuser: widget.currentuser)),
            buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: messagetextController,
              onChanged: (value) => message = value,
              decoration: const InputDecoration(
                hintText: "Write message...",
                hintStyle: TextStyle(color: Colors.black54),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: FloatingActionButton(
              onPressed: () {
                if (message.isNotEmpty) {
                  messagetextController.clear();
                  _firestore.collection('chat_room').add({
                    'message': message,
                    'sender': widget.currentuser,
                    'receiver': widget.receiver,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }
              },
              child: const Icon(Icons.send, color: Colors.white, size: 15),
              backgroundColor: Colors.blue,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  final bool isMe;

  const MessageBubble({
    required this.sender,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(sender, style: const TextStyle(color: Colors.black54)),
        Material(
          borderRadius: BorderRadius.circular(30),
          color: isMe ? Colors.lightBlueAccent : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(message, style: const TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class MessageStream extends StatelessWidget {
  final String currentuser;

  const MessageStream({required this.currentuser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('chat_room').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data!.docs;
          List<MessageBubble> messageWidgets = messages.map((message) {
            final messageData = message.data() as Map<String, dynamic>;
            final messageText = messageData['message'] ?? '';
            final messageSender = messageData['sender'] ?? '';

            return MessageBubble(
              sender: messageSender,
              message: messageText,
              isMe: currentuser == messageSender,
            );
          }).toList();

          return ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            children: messageWidgets,
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
