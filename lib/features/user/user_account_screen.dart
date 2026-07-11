import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/user/user_formatters.dart';

part 'user_account/panels.dart';
part 'user_account/shared_widgets.dart';


class UserAccountScreen extends StatefulWidget {
  const UserAccountScreen({super.key});

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthUser? _user;
  List<UserSession> _sessions = const [];
  bool _savingUsername = false;
  bool _savingPassword = false;
  bool _loadingSessions = true;
  bool _loggingOut = false;
  bool _deletingAccount = false;
  String? _sessionActionId;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String _usernameSuccess = '';
  String _usernameError = '';
  String _passwordSuccess = '';
  String _passwordError = '';
  String _sessionsError = '';
  String _accountActionError = '';

  @override
  void initState() {
    super.initState();
    _user = AuthSessionManager.instance.user;
    _usernameController.text = _user?.username ?? '';
    _loadSessions();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();

    setState(() {
      _usernameSuccess = '';
      _usernameError = '';
    });

    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Choisis un pseudo avant de sauvegarder.';
      });
      return;
    }

    if (username == _user?.username) {
      setState(() {
        _usernameSuccess = 'Ton pseudo est deja a jour.';
      });
      return;
    }

    setState(() {
      _savingUsername = true;
    });

    try {
      final user = await AuthSessionManager.instance.updateMe(
        username: username,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _usernameSuccess = 'Pseudo mis a jour.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _usernameError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingUsername = false;
        });
      }
    }
  }

  Future<void> _savePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _passwordSuccess = '';
      _passwordError = '';
    });

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _passwordError =
            'Remplis les trois champs pour changer ton mot de passe.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError =
            'Les deux nouveaux mots de passe ne correspondent pas.';
      });
      return;
    }

    setState(() {
      _savingPassword = true;
    });

    try {
      final user = await AuthSessionManager.instance.updateMe(
        currentPassword: currentPassword,
        password: newPassword,
      );

      if (!mounted) {
        return;
      }

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _user = user;
        _passwordSuccess = 'Mot de passe mis a jour.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _passwordError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingPassword = false;
        });
      }
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loadingSessions = true;
      _sessionsError = '';
    });

    try {
      final sessions = await AuthSessionManager.instance.fetchSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = sessions;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sessionsError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSessions = false;
        });
      }
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    setState(() {
      _sessionActionId = sessionId;
      _sessionsError = '';
    });

    try {
      await AuthSessionManager.instance.revokeSession(sessionId);

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = _sessions
            .where((session) => session.id != sessionId)
            .toList(growable: false);
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sessionsError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sessionActionId = null;
        });
      }
    }
  }

  Future<void> _revokeAllSessions() async {
    setState(() {
      _loadingSessions = true;
      _sessionsError = '';
    });

    try {
      await AuthSessionManager.instance.revokeAllSessions();

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
        _sessionsError = error.message;
        _loadingSessions = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _loggingOut = true;
      _accountActionError = '';
    });

    try {
      await AuthSessionManager.instance.logout();
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  Future<void> _openDeleteAccountDialog() async {
    if (_deletingAccount) {
      return;
    }

    setState(() {
      _accountActionError = '';
    });

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _DeleteAccountDialog(
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _deletingAccount = true;
      _accountActionError = '';
    });

    try {
      await AuthSessionManager.instance.deleteMe();

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
        _accountActionError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _deletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      currentRoute: AppRoutes.user,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                132,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const _UserAccountHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _UserInfoPanel(user: _user),
                    const SizedBox(height: AppSpacing.lg),
                    _UsernamePanel(
                      controller: _usernameController,
                      pending: _savingUsername,
                      successMessage: _usernameSuccess,
                      errorMessage: _usernameError,
                      onSubmit: _saveUsername,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PasswordPanel(
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                      pending: _savingPassword,
                      showCurrentPassword: _showCurrentPassword,
                      showNewPassword: _showNewPassword,
                      showConfirmPassword: _showConfirmPassword,
                      successMessage: _passwordSuccess,
                      errorMessage: _passwordError,
                      onSubmit: _savePassword,
                      onToggleCurrentPassword: () {
                        setState(() {
                          _showCurrentPassword = !_showCurrentPassword;
                        });
                      },
                      onToggleNewPassword: () {
                        setState(() {
                          _showNewPassword = !_showNewPassword;
                        });
                      },
                      onToggleConfirmPassword: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SessionsPanel(
                      sessions: _sessions,
                      pending: _loadingSessions,
                      errorMessage: _sessionsError,
                      actionSessionId: _sessionActionId,
                      onRefresh: _loadSessions,
                      onRevokeSession: _revokeSession,
                      onRevokeAllSessions: _revokeAllSessions,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AccountActionsPanel(
                      pending: _loggingOut || _deletingAccount,
                      errorMessage: _accountActionError,
                      onLogout: _logout,
                      onDeleteAccount: _openDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

