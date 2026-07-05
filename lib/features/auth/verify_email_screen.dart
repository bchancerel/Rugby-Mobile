import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_message.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_page_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    this.token = '',
    super.key,
  });

  final String token;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _pending = true;
  bool _hasTriedVerification = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verify();
    });
  }

  Future<void> _verify() async {
    setState(() {
      _pending = true;
      _hasTriedVerification = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (widget.token.isEmpty) {
        throw const AuthApiException(
          message: 'Le lien de verification est invalide.',
        );
      }

      final response = await AuthSessionManager.instance.verifyEmail(
        token: widget.token,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pending = false;
        _successMessage = response.message;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pending = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pending = false;
        _errorMessage = 'Une erreur est survenue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActionLink = !_pending &&
        (_successMessage != null ||
            _errorMessage != null ||
            _hasTriedVerification);

    return AuthPageShell(
      title: 'Verification email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'On verifie ton adresse email pour finaliser la securite de ton compte.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_pending && _successMessage == null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Verification en cours...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AuthMessage(message: _successMessage!),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AuthMessage(
              message: _errorMessage!,
              isError: true,
            ),
          ],
          if (_errorMessage != null && widget.token.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _pending ? 'Verification...' : 'Reessayer',
              icon: Icons.refresh,
              onPressed: _pending ? null : _verify,
            ),
          ],
          if (showActionLink) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => route.settings.name == AppRoutes.home,
                );
              },
              child: const Text('Retour a la connexion'),
            ),
          ],
        ],
      ),
    );
  }
}
