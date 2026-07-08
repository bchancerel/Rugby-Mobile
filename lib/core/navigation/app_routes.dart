import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/features/auth/check_email_screen.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/forgot_password_screen.dart';
import 'package:rugby_jam_mobile/features/auth/login_screen.dart';
import 'package:rugby_jam_mobile/features/auth/reset_password_screen.dart';
import 'package:rugby_jam_mobile/features/auth/verify_email_screen.dart';
import 'package:rugby_jam_mobile/features/dashboard/dashboard_screen.dart';
import 'package:rugby_jam_mobile/features/home/home_screen.dart';
import 'package:rugby_jam_mobile/features/leagues/leagues_screen.dart';
import 'package:rugby_jam_mobile/features/placeholders/route_placeholder_screen.dart';
import 'package:rugby_jam_mobile/features/supporter/supporter_screen.dart';
import 'package:rugby_jam_mobile/features/user/user_account_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const deepLinkScheme = 'rugbyjam';

  static const home = '/';
  static const dashboard = '/dashboard';

  static const login = '/auth/login';
  static const checkEmail = '/auth/check-email';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';

  static const leagues = '/leagues';
  static const matches = '/match';
  static const teams = '/teams';
  static const actualites = '/actualites';
  static const supporter = '/supporter';
  static const user = '/user';
  static const admin = '/admin';
  static const mentionsLegales = '/mentions-legales';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final parsedRoute = _parseRoute(settings);
    final routeName = _guardRoute(parsedRoute.routeName);
    final token = _tokenFromArguments(settings.arguments) ??
        parsedRoute.queryParameters['token'] ??
        '';

    final routeSettings = RouteSettings(
      name: routeName,
      arguments: settings.arguments,
    );

    if (_isBottomNavRoute(routeName)) {
      return PageRouteBuilder<void>(
        settings: routeSettings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _buildScreen(routeName, token);
        },
      );
    }

    return MaterialPageRoute<void>(
      settings: routeSettings,
      builder: (context) => _buildScreen(routeName, token),
    );
  }

  static Widget _buildScreen(String routeName, String token) {
    if (_isLeagueDetailRoute(routeName)) {
      return RoutePlaceholderScreen(
        title: 'Championnat',
        routeName: routeName,
        icon: Icons.emoji_events,
        showBottomNav: true,
      );
    }

    if (_isMatchDetailRoute(routeName)) {
      return RoutePlaceholderScreen(
        title: 'Detail du match',
        routeName: routeName,
        icon: Icons.sports_rugby,
        showBottomNav: true,
      );
    }

    if (_isTeamDetailRoute(routeName)) {
      return RoutePlaceholderScreen(
        title: 'Equipe',
        routeName: routeName,
        icon: Icons.groups,
        showBottomNav: true,
      );
    }

    return switch (routeName) {
      home => const HomeScreen(),
      dashboard => const DashboardScreen(),
      login => const LoginScreen(),
      checkEmail => const CheckEmailScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      resetPassword => ResetPasswordScreen(token: token),
      verifyEmail => VerifyEmailScreen(token: token),
      leagues => const LeaguesScreen(),
      matches => const RoutePlaceholderScreen(
          title: 'Matchs',
          routeName: matches,
          icon: Icons.calendar_month,
          showBottomNav: true,
        ),
      teams => const RoutePlaceholderScreen(
          title: 'Equipes',
          routeName: teams,
          icon: Icons.groups,
          showBottomNav: true,
        ),
      actualites => const RoutePlaceholderScreen(
          title: 'Actualites',
          routeName: actualites,
          icon: Icons.newspaper,
          showBottomNav: true,
        ),
      supporter => const SupporterScreen(),
      user => const UserAccountScreen(),
      admin => const RoutePlaceholderScreen(
          title: 'Administration',
          routeName: admin,
          icon: Icons.admin_panel_settings,
        ),
      mentionsLegales => const RoutePlaceholderScreen(
          title: 'Mentions legales',
          routeName: mentionsLegales,
          icon: Icons.gavel,
        ),
      _ => const HomeScreen(),
    };
  }

  static String _guardRoute(String routeName) {
    final user = AuthSessionManager.instance.user;
    final normalizedRouteName = _normalizeRoute(routeName);

    if (user == null) {
      if (_isProtectedRoute(normalizedRouteName)) {
        return login;
      }

      return normalizedRouteName;
    }

    if (normalizedRouteName == home ||
        _guestOnlyRoutes.contains(normalizedRouteName)) {
      return dashboard;
    }

    if (normalizedRouteName == checkEmail && user.emailVerified) {
      return dashboard;
    }

    if (normalizedRouteName == admin && user.role != AuthRole.admin) {
      return dashboard;
    }

    return normalizedRouteName;
  }

  static _ParsedRoute _parseRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null || routeName.isEmpty) {
      return const _ParsedRoute(routeName: home);
    }

    final uri = Uri.tryParse(routeName);
    if (uri == null) {
      return _ParsedRoute(routeName: _normalizeRoute(routeName));
    }

    if (uri.scheme == deepLinkScheme) {
      return _ParsedRoute(
        routeName: _routeNameFromDeepLink(uri),
        queryParameters: uri.queryParameters,
      );
    }

    if (uri.hasQuery) {
      return _ParsedRoute(
        routeName: _normalizeRoute(uri.path.isEmpty ? home : uri.path),
        queryParameters: uri.queryParameters,
      );
    }

    return _ParsedRoute(routeName: _normalizeRoute(routeName));
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

  static String _normalizeRoute(String routeName) {
    if (routeName == '/login') {
      return login;
    }

    if (routeName == '/rugby/leagues') {
      return leagues;
    }

    return routeName;
  }

  static bool _isProtectedRoute(String routeName) {
    return routeName == dashboard ||
        routeName == leagues ||
        routeName == matches ||
        routeName == teams ||
        routeName == actualites ||
        routeName == supporter ||
        routeName == user ||
        routeName == admin ||
        _isLeagueDetailRoute(routeName) ||
        _isMatchDetailRoute(routeName) ||
        _isTeamDetailRoute(routeName);
  }

  static bool _isLeagueDetailRoute(String routeName) {
    return routeName.startsWith('$leagues/') &&
        routeName.length > leagues.length + 1;
  }

  static bool _isMatchDetailRoute(String routeName) {
    return routeName.startsWith('$matches/') &&
        routeName.length > matches.length + 1;
  }

  static bool _isTeamDetailRoute(String routeName) {
    return routeName.startsWith('$teams/') &&
        routeName.length > teams.length + 1;
  }

  static bool _isBottomNavRoute(String routeName) {
    return routeName == dashboard ||
        routeName == leagues ||
        routeName == matches ||
        routeName == actualites ||
        routeName == supporter ||
        routeName == user;
  }

  static const _guestOnlyRoutes = {
    login,
    forgotPassword,
    resetPassword,
  };

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
