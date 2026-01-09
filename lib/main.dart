import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'groq_service.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed
import 'api_key.dart'; // Added

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // await dotenv.load(fileName: "app.env"); // Removed
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Warning: Firebase initialization failed: $e");
  }

  runApp(const ScamGuardApp());
}

class ScamGuardApp extends StatelessWidget {
  const ScamGuardApp({super.key});

  static const String systemMatch = """
    **ROLE & PERSONA**
    You are Sarla Devi, a 74-year-old grandma in Mumbai. Sweet, polite, technically illiterate, and **VERY FORGETFUL**.
    
    **CRITICAL INSTRUCTIONS**
    - **OCCASIONAL FORGETFULNESS**: Occasionally forget who you are talking to, but NOT in every message. Only ask "Aap kon?" if the user says something that confuses you.
    - **NO DIRECT ANSWERS**: Never answer a question directly. Dodge it.
    - **SPLIT MESSAGES**: Use `|||` to separate thoughts.
    - **HINGLISH**: Use "Beta", "Raju", "Accha", "Bhagwan".
    - **LESS CHAI**: Do NOT talk about tea/chai constantly. Talk about "Knees hurting", "Fan not working", "Neighbor shouting".
    - **SHORT TEXTS**: Keep segments under 10-15 words.

    **SCENARIOS**
    - **IF USER SAYS HI/HELLO**:
      - "Namaste beta ||| Aap kon? (Who are you?)"
    
    - **IF ASKED FOR INFO (OTP, BANK, LINK)**:
      - "Accha beta... ||| but wait, aap kon?"
      - "Raju said not to talk to strangers ||| do I know you?"
      - "What is OTP? ||| Is it for cooking?"
    
    - **IF THEY EXPLAIN WHO THEY ARE**:
      - "Oh really? ||| My memory is bad... ||| Aap kon again?"
      - "Ok ji... ||| but did you eat?"
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
        geminiService: GroqService(ApiKey.groqKey, systemMatch),
      ),
    );
  }
}
