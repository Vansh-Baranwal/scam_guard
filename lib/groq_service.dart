import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroqService {
  final String apiKey;
  final String systemInstruction;
  final List<Map<String, String>> _history = [];
  bool _isScamMode = false;

  // Keywords that trigger the "Trap"
  static const List<String> _scamKeywords = [
    'urgency', 'blocked', 'money', 'otp', 'kyc', 'refund', 
    'verify', 'bank', 'account', 'credit card', 'debit card',
    'password', 'pin', 'code', 'expires', 'jail', 'police'
  ];

  GroqService(this.apiKey, this.systemInstruction);

  Future<String> sendMessage(String message) async {
    // 1. Latency Simulation (3-5 seconds)
    final randomDelay = 3000 + Random().nextInt(2000);
    await Future.delayed(Duration(milliseconds: randomDelay));

    // 2. Scam Analysis (Phase 1)
    if (!_isScamMode) {
      final lowerMsg = message.toLowerCase();
      for (final keyword in _scamKeywords) {
        if (lowerMsg.contains(keyword)) {
          _isScamMode = true;
          if (kDebugMode) {
            print('ScamGuard: SCAM DETECTED! Keyword: $keyword');
          }
          break;
        }
      }
    }

    // 3. Construct Message
    _history.add({'role': 'user', 'content': message});

    final messages = [
      {'role': 'system', 'content': systemInstruction},
      ..._history,
    ];

    int retryCount = 0;
    while (true) {
      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': messages,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final replyText = data['choices'][0]['message']['content'];
          _history.add({'role': 'assistant', 'content': replyText});
          return replyText;
        } else if (response.statusCode == 429) {
             retryCount++;
            if (retryCount >= 3) {
              throw Exception('Rate Limit Exceeded. Please try again later.');
            }
             await Future.delayed(Duration(seconds: 2 * retryCount));
             continue;
        } else {
          throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
        }

      } catch (e) {
          if (kDebugMode) print('Groq Error: $e');
           // Re-throw if it's not a retryable error or max retries reached
           if (!e.toString().contains('Rate Limit')) {
             throw Exception('Groq Error: $e');
           }
            // If it was a rate limit handled above, loop continues.
            // If it was caught here as generic exception but logically flow should handled inside loop logic for specific codes.
            // To be safe, rethrow unless we want infinite retries (we don't).
             throw Exception('Connection Error: $e');

      }
    }
  }

  bool get isScamMode => _isScamMode;
}
