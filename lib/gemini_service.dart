
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final GenerativeModel _model;
  final List<Content> _history = [];
  bool _isScamMode = false;

  // Keywords that trigger the "Trap"
  static const List<String> _scamKeywords = [
    'urgency', 'blocked', 'money', 'otp', 'kyc', 'refund', 
    'verify', 'bank', 'account', 'credit card', 'debit card',
    'password', 'pin', 'code', 'expires', 'jail', 'police'
  ];

  GeminiService(String apiKey, String systemInstruction)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: apiKey,
          systemInstruction: Content.system(systemInstruction),
        );

  Future<String> sendMessage(String message) async {
    // 1. Latency Simulation (3-5 seconds)
    final randomDelay = 3000 + Random().nextInt(2000);
    await Future.delayed(Duration(milliseconds: randomDelay));

    try {
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
      // If scam detected for the first time or active, we treat it normally 
      // but the SYSTEM PROMPT will handle the "Double Agent" logic based on context.
      // However, to be extra safe, we could inject a "hidden" system note 
      // into the chat history if the prompt needs a nudge, but a robust system prompt is best.
      
      final content = Content.text(message);
      _history.add(content);

      int retryCount = 0;
      while (true) {
        try {
          final response = await _model.generateContent(_history);
          final replyText = response.text ?? "...";
          _history.add(Content.model([TextPart(replyText)]));
          return replyText;
        } catch (e) {
          // Check for rate limit/quota errors (usually contain 429 or quota)
          if (e.toString().toLowerCase().contains('429') || 
              e.toString().toLowerCase().contains('quota') ||
              e.toString().toLowerCase().contains('resource exhausted')) {
            retryCount++;
            if (retryCount >= 3) {
              if (kDebugMode) print('Gemini Error (Max Retries): $e');
              throw Exception('Server busy (Rate Limit). Please try again in a moment. ($e)');
            }
            if (kDebugMode) print('Quota limit hit, retrying ($retryCount)...');
            await Future.delayed(Duration(seconds: 2 * retryCount)); // 2s, 4s, 6s...
            continue;
          }
          if (kDebugMode) print('Gemini Error: $e');
          throw Exception('Gemini Error: $e');
        }
      }
    }
  }

  bool get isScamMode => _isScamMode;
}
