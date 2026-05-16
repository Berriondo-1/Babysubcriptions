import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/screens/baby_list_screen.dart';
import 'package:baby_subscription/screens/welcome_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
      home: const _AppRouter(),
    );
  }
}

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
        await context.read<BabyProvider>().loadProfiles(authProv.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    if (status == AuthStatus.unknown) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (status == AuthStatus.authenticated) {
      return const BabyListScreen();
    }
    return const WelcomeScreen();
  }
}