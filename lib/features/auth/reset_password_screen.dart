import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_message.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_page_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    this.token = '',
    super.key,
  });

  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  bool _pending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;

    setState(() {
      _pending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (widget.token.isEmpty) {
        throw const AuthApiException(
          message: 'Le lien de reinitialisation est invalide.',
        );
      }

      if (password.length < 8) {
        throw const AuthApiException(
          message: 'Le mot de passe doit contenir au moins 8 caracteres.',
        );
      }

      if (password != passwordConfirmation) {
        throw const AuthApiException(
          message: 'Les mots de passe ne correspondent pas.',
        );
      }

      final response = await AuthSessionManager.instance.resetPassword(
        token: widget.token,
        password: password,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = response.message;
        _passwordController.clear();
        _passwordConfirmationController.clear();
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Une erreur est survenue.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Nouveau mot de passe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Choisis un nouveau mot de passe pour recuperer l'acces a ton compte.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            enabled: !_pending,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              prefixIcon: Icon(Icons.lock_outline),
              helperText:
                  '8 caracteres, une majuscule, un chiffre et un special.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passwordConfirmationController,
            enabled: !_pending,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_pending) {
                _submit();
              }
            },
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthMessage(message: _successMessage!),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthMessage(
              message: _errorMessage!,
              isError: true,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _pending ? 'Enregistrement...' : 'Changer le mot de passe',
            icon: Icons.password_outlined,
            onPressed: _pending ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _pending
                ? null
                : () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => route.settings.name == AppRoutes.home,
                    );
                  },
            child: const Text('Retour a la connexion'),
          ),
        ],
      ),
    );
  }
}
