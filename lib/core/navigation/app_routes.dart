import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/features/auth/check_email_screen.dart';
import 'package:rugby_jam_mobile/features/auth/forgot_password_screen.dart';
import 'package:rugby_jam_mobile/features/auth/login_screen.dart';
import 'package:rugby_jam_mobile/features/auth/reset_password_screen.dart';
import 'package:rugby_jam_mobile/features/auth/verify_email_screen.dart';
import 'package:rugby_jam_mobile/features/home/home_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const deepLinkScheme = 'rugbyjam';

  static const home = '/';
  static const login = '/login';
  static const checkEmail = '/auth/check-email';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final parsedRoute = _parseRoute(settings);
    final routeName = parsedRoute.routeName;
    final token = _tokenFromArguments(settings.arguments) ??
        parsedRoute.queryParameters['token'] ??
        '';

    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: routeName,
        arguments: settings.arguments,
      ),
      builder: (context) {
        return switch (routeName) {
          home => const HomeScreen(),
          login => const LoginScreen(),
          checkEmail => const CheckEmailScreen(),
          forgotPassword => const ForgotPasswordScreen(),
          resetPassword => ResetPasswordScreen(token: token),
          verifyEmail => VerifyEmailScreen(token: token),
          _ => const HomeScreen(),
        };
      },
    );
  }

  static _ParsedRoute _parseRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null || routeName.isEmpty) {
      return const _ParsedRoute(routeName: home);
    }

    final uri = Uri.tryParse(routeName);
    if (uri == null) {
      return _ParsedRoute(routeName: routeName);
    }

    if (uri.scheme == deepLinkScheme) {
      return _ParsedRoute(
        routeName: _routeNameFromDeepLink(uri),
        queryParameters: uri.queryParameters,
      );
    }

    if (uri.hasQuery) {
      return _ParsedRoute(
        routeName: uri.path.isEmpty ? home : uri.path,
        queryParameters: uri.queryParameters,
      );
    }

    return _ParsedRoute(routeName: routeName);
  }

  static String _routeNameFromDeepLink(Uri uri) {
    if (uri.host == 'auth') {
      return '/auth${uri.path}';
    }

    if (uri.path.isNotEmpty) {
      return uri.path;
    }

    return home;
  }

  static String? _tokenFromArguments(Object? arguments) {
    if (arguments is String) {
      return arguments;
    }

    if (arguments is Map<String, String>) {
      return arguments['token'] ?? '';
    }

    if (arguments is Map) {
      final token = arguments['token'];
      return token is String ? token : '';
    }

    return null;
  }
}

class _ParsedRoute {
  const _ParsedRoute({
    required this.routeName,
    this.queryParameters = const {},
  });

  final String routeName;
  final Map<String, String> queryParameters;
}
