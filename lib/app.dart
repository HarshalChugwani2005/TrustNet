import 'package:flutter/material.dart';

import 'screens/auth_flow.dart';
import 'theme/app_theme.dart';

class TrustNetApp extends StatelessWidget {
  const TrustNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrustNet',
      theme: buildAppTheme(context),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
