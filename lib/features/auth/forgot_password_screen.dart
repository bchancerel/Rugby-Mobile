import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_message.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_page_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _pending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    setState(() {
      _pending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (email.isEmpty || !email.contains('@')) {
        throw const AuthApiException(message: 'Entre une adresse email valide.');
      }

      final response = await AuthSessionManager.instance.forgotPassword(
        email: email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = response.message;
        _emailController.clear();
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
      title: 'Mot de passe oublie',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Entre ton email et on t'envoie un lien pour reinitialiser ton mot de passe.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _emailController,
            enabled: !_pending,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_pending) {
                _submit();
              }
            },
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthMessage(
              message: _successMessage!,
            ),
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
            label: _pending ? 'Envoi...' : 'Envoyer le lien',
            icon: Icons.send_outlined,
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
