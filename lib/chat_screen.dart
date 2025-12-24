
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'groq_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final GroqService geminiService;

  const ChatScreen({super.key, required this.geminiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('scam_guard_session_id');

    if (storedId == null) {
      storedId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('scam_guard_session_id', storedId);
    }

    if (mounted) {
      setState(() {
        _sessionId = storedId;
      });
    }
  }

  void _sendMessage() async {
    if (_sessionId == null) return;
    
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    // _scrollToBottom(); // StreamBuilder handles scroll on new item usually, or we trigger it

    setState(() {
      _isLoading = true;
    });

    // 1. Write User Message to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_sessionId)
          .collection('messages')
          .add({
        'text': text,
        'sender': 'user',
        'isUser': true, // Add this for easier querying/filtering if needed
        'timestamp': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Firestore Error (User): $e");
    }

    // 2. Get Bot Response
    try {
      final response = await widget.geminiService.sendMessage(text);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Split by "|||" and add messages one by one
        final parts = response.split('|||');
        for (final part in parts) {
          if (part.trim().isNotEmpty) {
            await Future.delayed(Duration(milliseconds: 1500 + part.length * 50)); 
            
            if (mounted) {
               // Write Bot Message to Firestore
               try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_sessionId)
                      .collection('messages')
                      .add({
                    'text': part.trim(),
                    'sender': 'bot',
                    'isUser': false,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  _scrollToBottom();
               } catch (e) {
                  debugPrint("Firestore Error (Bot): $e");
               }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _clearChat() async {
    if (_sessionId == null) return;

    // 1. Delete from Firestore
    try {
      final collection = FirebaseFirestore.instance
          .collection('chats')
          .doc(_sessionId)
          .collection('messages');
      
      final snapshots = await collection.get();
      for (final doc in snapshots.docs) {
        await doc.reference.delete();
      }
      // Delete session doc (optional)
      // await FirebaseFirestore.instance.collection('chats').doc(_sessionId).delete();
    } catch (e) {
      debugPrint("Error deleting chat: $e");
    }

    // 2. Clear Session (Start Fresh)
    final prefs = await SharedPreferences.getInstance();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString('scam_guard_session_id', newId);

    if (mounted) {
      setState(() {
        _sessionId = newId;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to allow list to render
      Future.delayed(const Duration(milliseconds: 100), () { 
        if (_scrollController.hasClients) {
           _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
             backgroundColor: Colors.grey[300],
             child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sarla Devi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
             const Text(
               'Online',
               style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
             ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage("https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png"), 
            fit: BoxFit.cover,
            opacity: 0.1, 
          ),
          color: Color(0xFFE5DDD5), 
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(_sessionId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // Auto-scroll to bottom on new message
                  // Note: In production, might want smarter logic (only if already at bottom)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients && docs.isNotEmpty) {
                       // _scrollToBottom(); // Can cause jitter if not careful
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: docs.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isUser = data['sender'] == 'user';
                      
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFFDCF8C6) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                data['text'] ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(data['timestamp'] as Timestamp?),
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
            if (_isLoading)
              Container(
                 padding: const EdgeInsets.all(8),
                 color: Colors.transparent,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const CircularProgressIndicator(strokeWidth: 2),
                     const SizedBox(width: 10),
                     Text("Sarla Devi is typing...", style: TextStyle(color: Colors.grey[700])),
                   ],
                 ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 2, offset: const Offset(0,1))],
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF075E54),
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
