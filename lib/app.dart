import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/auth_flow.dart';
import 'theme/app_theme.dart';

class TrustNetApp extends StatelessWidget {
  const TrustNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrustNet',
      theme: buildAppTheme(context),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
