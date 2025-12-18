
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gemini_service.dart';

class ChatScreen extends StatefulWidget {
  final GeminiService geminiService;

  const ChatScreen({super.key, required this.geminiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // {text, isUser, time}
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await widget.geminiService.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add({
            'text': response,
            'isUser': false,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Add error as a visible message for debugging
          _messages.add({
            'text': "DEBUG ERROR: ${e.toString()}",
            'isUser': false,
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
             backgroundColor: Colors.grey[300],
             child: const Icon(Icons.person, color: Colors.white, size: 30),
             // backgroundImage: NetworkImage('...'), // Add image if available
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sarla Devi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.geminiService.isScamMode)
               const Text(
                'Confused...', // Debug indicator or fun detail?
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              )
            else
              const Text(
                'Online',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage("https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png"), // WhatsApp bg pattern
            fit: BoxFit.cover,
            opacity: 0.1, 
          ),
          color: Color(0xFFE5DDD5), // WhatsApp BG color
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'];
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
                            msg['text'],
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(msg['time']),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
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
