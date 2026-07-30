import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  runApp(const AgroPlusApp());
}

class AgroPlusApp extends StatelessWidget {
  const AgroPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuthStatus(),
      child: MaterialApp(
        title: 'AgroPlus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
        home: const _StartupGate(),
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
