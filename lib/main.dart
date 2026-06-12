import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/providers/consumption_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/providers/stock_provider.dart';
import 'package:baby_subscription/screens/baby_list_screen.dart';
import 'package:baby_subscription/screens/reorder_screen.dart';
import 'package:baby_subscription/screens/welcome_screen.dart';
import 'package:baby_subscription/services/notification_service.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baby_subscription/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ConsumptionProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: const BabySubscriptionApp(),
    ),
  );
}

class BabySubscriptionApp extends StatelessWidget {
  const BabySubscriptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabySubscription',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      home: const _AppRouter(),
      routes: {
        '/reorder': (context) {
          final babyProv = Provider.of<BabyProvider>(context, listen: false);
          final baby = babyProv.selectedProfile ?? babyProv.profiles.firstOrNull;
          if (baby == null) return const BabyListScreen();
          return ReorderScreen(babyProfile: baby);
        },
      },
    );
  }
} // ← cierre de BabySubscriptionApp

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProv = context.read<AuthProvider>();
      await authProv.checkSession();
      if (authProv.status == AuthStatus.authenticated && mounted) {
        await context.read<BabyProvider>().loadProfiles(
          authProv.currentUser!.id!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    if (status == AuthStatus.unknown) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (status == AuthStatus.authenticated) {
      return const BabyListScreen();
    }
    return const WelcomeScreen();
  }
}