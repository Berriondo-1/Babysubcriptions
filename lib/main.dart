import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/screens/baby_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const BabySubscriptionApp());
}

class BabySubscriptionApp extends StatelessWidget {
  const BabySubscriptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BabyProvider(),
      child: MaterialApp(
        title: 'BabySubscription',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F7CAC),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F8FC),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF223046),
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF4F7CAC)),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        home: const BabyRegistrationScreen(),
      ),
    );
  }
}
