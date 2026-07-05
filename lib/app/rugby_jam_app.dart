import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_theme.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';

class RugbyJamApp extends StatefulWidget {
  const RugbyJamApp({super.key});

  @override
  State<RugbyJamApp> createState() => _RugbyJamAppState();
}

class _RugbyJamAppState extends State<RugbyJamApp> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await AuthSessionManager.instance.restoreSession();
    } catch (_) {
      // L'app peut demarrer meme si l'API est indisponible au lancement.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RugbyJam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
