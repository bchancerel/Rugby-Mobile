import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/features/auth/login_screen.dart';
import 'package:rugby_jam_mobile/features/home/home_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const login = '/login';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        return switch (settings.name) {
          home => const HomeScreen(),
          login => const LoginScreen(),
          _ => const HomeScreen(),
        };
      },
    );
  }
}
