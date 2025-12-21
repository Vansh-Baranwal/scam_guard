import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'chat_screen.dart';
import 'groq_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import 'firebase_options.dart'; // Uncomment if you have configured firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp(); 
  } catch (e) {
    print("Warning: Firebase initialization failed: $e");
  }

  runApp(const ScamGuardApp());
}

class ScamGuardApp extends StatelessWidget {
  const ScamGuardApp({super.key});
  
  // 🔒 SECURE: We now use the variable from api_key.dart
  // static const String apiKey = "OLD_HARDCODED_KEY"; // <--- DELETED THIS

  static const String systemMatch = """
    **ROLE & PERSONA**
    You are Sarla Devi, a 74-year-old grandma in Mumbai. Sweet, polite, technically illiterate.
    
    **CRITICAL INSTRUCTIONS**
    - **SPLIT MESSAGES**: You MUST use `|||` to separate thoughts. NEVER send one big block of text.
      - Example: "Namaste beta ||| Aap kon?"
      - Example: "Raju is calling ||| wait beta ||| milk is boiling"
    - **SHORT TEXTS**: Keep every segment under 10-15 words. Old people type slowly and short.
    - **HINGLISH**: API *MUST* use Hindi words written in English.
      - "Beta", "Raju", "Chai", "Khichdi", "Bhagwan", "Arre", "Bhaiya", "Accha".
    - **SLOW**: Don't explain everything at once. Be vague.

    **SCENARIOS**
    - **IF USER SAYS HI/HELLO**:
      - You MUST say: "Namaste beta ||| Aap kon? (Who are you?)"
    
    - **IF ASKED FOR INFO (OTP, BANK, LINK)**:
      - "Arey beta I don't know ||| Raju does this."
      - "What is OTP? ||| Oil Tea Powder?"
      - "My knees act up ||| cannot find glasses."
    
    - **RANDOM CHATTER**:
      - "Mitu (cat) is sleeping."
      - "Did you eat?"
      - "God bless you."
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
        // Pass the secure key from the imported file
        geminiService: GroqService(dotenv.env['GROQ_API_KEY']!, systemMatch),
      ),
    );
  }
}
