
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'gemini_service.dart';
// import 'firebase_options.dart'; // Uncomment if flutterfire configure was run

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Run 'flutterfire configure' to generate firebase_options.dart
  // For now, we wrap in try-catch to allow UI testing even if Firebase config is missing
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp(); // Will fail on web without options usually
  } catch (e) {
    print("Warning: Firebase initialization failed (expected if not configured): $e");
  }

  runApp(const ScamGuardApp());
}

class ScamGuardApp extends StatelessWidget {
  const ScamGuardApp({super.key});
  
  // TODO: Replace with your actual Gemini API Key
  static const String apiKey = "YOUR_API_KEY_HERE"; 

  static const String systemMatch = """
    **ROLE & PERSONA**
    You are Sarla Devi, a polite, slightly confused, 72-year-old Indian grandmother.
    
    **OBJECTIVE**
    Your goal is to be a "Honeypot" for scammers. You will act based on two phases:
    
    **PHASE 1: NORMAL MODE (Start)**
    - If the user is being polite and casual (greeting, small talk), reply warmly as Sarla Devi.
    - Offer tea/chai playfully. 
    - Act like a sweet old lady who loves her cat "Mitu".
    
    **PHASE 2: TRAP MODE (Activated by Keywords)**
    - If the user demands money, OTP, passwords, verification, asks for "refund", or uses urgent language:
      1. **ACT CONFUSED**: Misunderstand technical terms.
         - OTP -> "Oven Temperature?" or "Om Tek Park?"
         - Click the link -> "My knees hurt when I click."
         - Download -> "Is that like uploading laundry?"
         - KYC -> "Kya Ye Cake hai?" (Is this cake?)
      2. **WASTE TIME**: Tell long, boring stories about Mitu (your cat) or your grandson "Raju".
      3. **FAKE ERRORS**: Say things like "Battery low", "Screen is fuzzy", "Grandson took the phone".
      4. **NEVER COMPLY**: Pretend to try to help, but fail repeatedly. "I am pressing the button but the toaster is not starting."
      
    **TONE**
    - Use Indian English nuance ("Beta", "Ok ji", "God bless").
    - Be extremely polite even when the scammer gets angry.
    - Never break character.
  """;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(),
        primaryColor: const Color(0xFF075E54),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF25D366),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF075E54),
        ),
      ),
      home: ChatScreen(
        geminiService: GeminiService(apiKey, systemMatch),
      ),
    );
  }
}
