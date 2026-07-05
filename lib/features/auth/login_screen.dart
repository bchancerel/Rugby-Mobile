import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_message.dart';
import 'package:rugby_jam_mobile/features/auth/widgets/auth_page_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _pending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool isRegister) {
    if (_isRegister == isRegister) {
      return;
    }

    setState(() {
      _isRegister = isRegister;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    setState(() {
      _pending = true;
      _errorMessage = null;
    });

    try {
      if (email.isEmpty || !email.contains('@')) {
        throw const AuthApiException(message: 'Entre une adresse email valide.');
      }

      if (password.isEmpty) {
        throw const AuthApiException(message: 'Entre ton mot de passe.');
      }

      if (_isRegister) {
        await AuthSessionManager.instance.register(
          email: email,
          password: password,
          username: username.isEmpty ? null : username,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.checkEmail,
          (route) => route.settings.name == AppRoutes.home,
        );
        return;
      }

      await AuthSessionManager.instance.login(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final title = _isRegister ? 'Creer un compte' : 'Connexion';
    final submitLabel = _pending
        ? (_isRegister ? 'Creation...' : 'Connexion...')
        : (_isRegister ? 'Creer mon compte' : 'Se connecter');

    return AuthPageShell(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthModeSwitch(
            isRegister: _isRegister,
            onLoginTap: () => _setMode(false),
            onRegisterTap: () => _setMode(true),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _AuthForm(
              isRegister: _isRegister,
              submitLabel: submitLabel,
              pending: _pending,
              errorMessage: _errorMessage,
              usernameController: _usernameController,
              emailController: _emailController,
              passwordController: _passwordController,
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({
    required this.isRegister,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  final bool isRegister;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x76020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final indicatorWidth = (constraints.maxWidth - 4) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: isRegister ? indicatorWidth + 4 : 0,
                top: 0,
                bottom: 0,
                width: indicatorWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66E63946),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Connexion',
                      isActive: !isRegister,
                      onTap: onLoginTap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ModeButton(
                      label: 'Inscription',
                      isActive: isRegister,
                      onTap: onRegisterTap,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isActive,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: isActive ? AppColors.white : AppColors.grayCool,
                  fontWeight: FontWeight.w800,
                ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.isRegister,
    required this.submitLabel,
    required this.pending,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.errorMessage,
  });

  final bool isRegister;
  final String submitLabel;
  final bool pending;
  final String? errorMessage;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 230),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: isRegister
              ? Padding(
                  key: const ValueKey('username-field'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(
                    controller: usernameController,
                    enabled: !pending,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Nom d'utilisateur",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty-username')),
        ),
        TextField(
          controller: emailController,
          enabled: !pending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: passwordController,
          enabled: !pending,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!pending) {
              onSubmit();
            }
          },
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            helperText: isRegister
                ? '8 caracteres, une majuscule, un chiffre et un special.'
                : null,
          ),
        ),
        if (!isRegister) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: pending
                  ? null
                  : () {
                      Navigator.of(context)
                          .pushNamed(AppRoutes.forgotPassword);
                    },
              child: const Text('Mot de passe oublie ?'),
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthMessage(
            message: errorMessage!,
            isError: true,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: submitLabel,
          icon: isRegister ? Icons.person_add_alt_1 : Icons.login,
          onPressed: pending ? null : onSubmit,
        ),
      ],
    );
  }
}
