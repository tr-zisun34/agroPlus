import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/locale_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/farm_provider.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const AgroPlusApp());
}

class AgroPlusApp extends StatelessWidget {
  const AgroPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => FarmProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'AgroPlus',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingAuth) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return auth.isLoggedIn ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}
