import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_message.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_page_shell.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final TextEditingController _verificationCodeController =
      TextEditingController();

  bool _pending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _verificationCodeController.text.trim();

    setState(() {
      _pending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
        throw const AuthApiException(
          message: 'Entre le code a 6 chiffres recu par email.',
        );
      }

      final response = await AuthSessionManager.instance.verifyEmail(
        code: code,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
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

  Future<void> _resendVerification() async {
    setState(() {
      _pending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await AuthSessionManager.instance.resendVerification();

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = response.message;
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
      title: 'Verifie tes mails',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Ton compte est cree. On t'a envoye un code par email pour activer ton acces.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AuthMessage(
            message:
                'Ouvre ta boite mail, recopie le code RugbyJam a 6 chiffres, puis valide-le ici.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _verificationCodeController,
            enabled: !_pending,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_pending) {
                _verifyCode();
              }
            },
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Code de verification',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _pending ? 'Verification...' : 'Valider le code',
            icon: Icons.verified_outlined,
            onPressed: _pending ? null : _verifyCode,
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
            label: _pending ? 'Envoi...' : 'Renvoyer le code',
            icon: Icons.mark_email_unread_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _pending ? null : _resendVerification,
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
