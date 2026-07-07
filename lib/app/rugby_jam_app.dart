import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_theme.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';

class RugbyJamApp extends StatefulWidget {
  const RugbyJamApp({super.key});

  @override
  State<RugbyJamApp> createState() => _RugbyJamAppState();
}

class _RugbyJamAppState extends State<RugbyJamApp> {
  _AppSessionState _sessionState = _AppSessionState.checkingStoredSession;

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final hasStoredSession =
        await AuthSessionManager.instance.hasStoredSession();

    if (!hasStoredSession) {
      if (mounted) {
        setState(() {
          _sessionState = _AppSessionState.guest;
        });
      }
      return;
    }

    try {
      await AuthSessionManager.instance.restoreSession();
    } catch (_) {
      // L'app peut demarrer meme si l'API est indisponible au lancement.
    } finally {
      if (mounted) {
        setState(() {
          _sessionState = AuthSessionManager.instance.isAuthenticated
              ? _AppSessionState.authenticated
              : _AppSessionState.guest;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_sessionState),
      title: 'RugbyJam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _sessionState == _AppSessionState.checkingStoredSession
          ? const _AppBootstrapScreen()
          : null,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

enum _AppSessionState {
  checkingStoredSession,
  guest,
  authenticated,
}

class _AppBootstrapScreen extends StatelessWidget {
  const _AppBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
