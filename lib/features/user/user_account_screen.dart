import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';

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

class _UserAccountHeader extends StatelessWidget {
  const _UserAccountHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon compte',
            style: textTheme.displayLarge?.copyWith(fontSize: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gere ton profil et tes informations RugbyJam.',
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _UserInfoPanel extends StatelessWidget {
  const _UserInfoPanel({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final verified = user?.emailVerified == true;

    return _UserPanel(
      title: 'Mes infos',
      icon: Icons.person,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentitySummary(
            username: _fallback(user?.username, 'Non renseigne'),
            email: _fallback(user?.email, 'Non disponible'),
            verified: verified,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoTile(
            icon: verified ? Icons.verified : Icons.mark_email_unread,
            label: 'Statut',
            value: verified ? 'Email verifie' : 'Email non verifie',
            valueColor: verified
                ? const Color(0xFF9AF2C2)
                : const Color(0xFFFFC1C7),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.shield_outlined,
                  label: 'Role',
                  value: _formatRole(user?.role),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoTile(
                  icon: Icons.event_available,
                  label: 'Creation',
                  value: _formatDate(user?.createdAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsernamePanel extends StatelessWidget {
  const _UsernamePanel({
    required this.controller,
    required this.pending,
    required this.successMessage,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool pending;
  final String successMessage;
  final String errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _UserPanel(
      title: 'Modifier mon pseudo',
      icon: Icons.badge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InputLabel(label: 'Pseudo'),
          TextField(
            controller: controller,
            enabled: !pending,
            minLines: 1,
            maxLength: 30,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'ton pseudo',
              counterText: '',
            ),
          ),
          if (successMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineMessage.success(successMessage),
          ],
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineMessage.error(errorMessage),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PanelButton(
            label: pending ? 'Sauvegarde...' : 'Sauvegarder',
            icon: Icons.save,
            onPressed: pending ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PasswordPanel extends StatelessWidget {
  const _PasswordPanel({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.pending,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.successMessage,
    required this.errorMessage,
    required this.onSubmit,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool pending;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final String successMessage;
  final String errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return _UserPanel(
      title: 'Modifier mon mot de passe',
      icon: Icons.lock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(
            label: 'Ancien mot de passe',
            controller: currentPasswordController,
            enabled: !pending,
            visible: showCurrentPassword,
            onToggle: onToggleCurrentPassword,
          ),
          const SizedBox(height: AppSpacing.md),
          _PasswordField(
            label: 'Nouveau mot de passe',
            controller: newPasswordController,
            enabled: !pending,
            visible: showNewPassword,
            onToggle: onToggleNewPassword,
          ),
          const SizedBox(height: AppSpacing.md),
          _PasswordField(
            label: 'Confirmer le nouveau mot de passe',
            controller: confirmPasswordController,
            enabled: !pending,
            visible: showConfirmPassword,
            onToggle: onToggleConfirmPassword,
          ),
          if (successMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineMessage.success(successMessage),
          ],
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineMessage.error(errorMessage),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Minimum 8 caracteres, avec au moins une majuscule, un chiffre et un caractere special.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9AF2C2),
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PanelButton(
            label: pending ? 'Sauvegarde...' : 'Changer le mot de passe',
            icon: Icons.lock_reset,
            onPressed: pending ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SessionsPanel extends StatelessWidget {
  const _SessionsPanel({
    required this.sessions,
    required this.pending,
    required this.errorMessage,
    required this.actionSessionId,
    required this.onRefresh,
    required this.onRevokeSession,
    required this.onRevokeAllSessions,
  });

  final List<UserSession> sessions;
  final bool pending;
  final String errorMessage;
  final String? actionSessionId;
  final VoidCallback onRefresh;
  final ValueChanged<String> onRevokeSession;
  final VoidCallback onRevokeAllSessions;

  @override
  Widget build(BuildContext context) {
    return _UserPanel(
      title: 'Sessions actives',
      icon: Icons.devices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Appareils connectes a ton compte.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _IconPanelButton(
                icon: Icons.refresh,
                onPressed: pending ? null : onRefresh,
              ),
            ],
          ),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineMessage.error(errorMessage),
          ],
          const SizedBox(height: AppSpacing.md),
          if (pending && sessions.isEmpty)
            const _EmptyPanelMessage(message: 'Chargement des sessions...')
          else if (sessions.isEmpty)
            const _EmptyPanelMessage(message: 'Aucune session active trouvee.')
          else
            ...sessions.map(
              (session) => _SessionTile(
                session: session,
                pending: pending || actionSessionId == session.id,
                onDelete: () => onRevokeSession(session.id),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _DangerPanelButton(
            label: 'Supprimer toutes les sessions',
            icon: Icons.logout,
            onPressed: pending || sessions.isEmpty ? null : onRevokeAllSessions,
          ),
        ],
      ),
    );
  }
}

class _AccountActionsPanel extends StatelessWidget {
  const _AccountActionsPanel({
    required this.pending,
    required this.errorMessage,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final bool pending;
  final String errorMessage;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return _UserPanel(
      title: 'Actions du compte',
      icon: Icons.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage.isNotEmpty) ...[
            _InlineMessage.error(errorMessage),
            const SizedBox(height: AppSpacing.md),
          ],
          _PanelButton(
            label: pending ? 'Deconnexion...' : 'Se deconnecter',
            icon: Icons.logout,
            onPressed: pending ? null : onLogout,
          ),
          const SizedBox(height: AppSpacing.md),
          _SubtleDangerButton(
            label: 'Supprimer mon compte',
            icon: Icons.delete_forever,
            onPressed: pending ? null : onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.appBackground,
          border: Border.all(color: const Color(0x47FF4655)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 42,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Supprimer le compte ?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tu es sur le point de supprimer ton compte RugbyJam. Cette action est definitive.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Annuler'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DangerPanelButton(
                label: 'Oui, supprimer',
                icon: Icons.delete_forever,
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserPanel extends StatelessWidget {
  const _UserPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x7A020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  const _IdentitySummary({
    required this.username,
    required this.email,
    required this.verified,
  });

  final String username;
  final String email;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66020617),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x24FF4655),
                border: Border.all(color: const Color(0x52FF4655)),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF9AF2C2),
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.grayLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x4D020617),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.grayCool,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grayLight,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.visible,
    required this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(label: label),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: !visible,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: enabled ? onToggle : null,
              icon: Icon(
                visible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage._({
    required this.message,
    required this.background,
    required this.border,
    required this.textColor,
  });

  const _InlineMessage.success(String message)
      : this._(
          message: message,
          background: const Color(0x243FB984),
          border: const Color(0x663FB984),
          textColor: const Color(0xFF9AF2C2),
        );

  const _InlineMessage.error(String message)
      : this._(
          message: message,
          background: const Color(0x24FF4655),
          border: const Color(0x66FF4655),
          textColor: const Color(0xFFFFC1C7),
        );

  final String message;
  final Color background;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _DangerPanelButton extends StatelessWidget {
  const _DangerPanelButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF9AA3),
        side: const BorderSide(color: Color(0x66FF4655)),
      ),
    );
  }
}

class _SubtleDangerButton extends StatelessWidget {
  const _SubtleDangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.grayCool,
        side: const BorderSide(color: Color(0x24FFFFFF)),
        backgroundColor: const Color(0x3D020617),
      ),
    );
  }
}

class _IconPanelButton extends StatelessWidget {
  const _IconPanelButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.white,
      style: IconButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x52020617),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.pending,
    required this.onDelete,
  });

  final UserSession session;
  final bool pending;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x57020617),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fallback(session.userAgent, 'Session inconnue'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'IP ${_fallback(session.ip, 'inconnue')} - Creee le ${_formatDateTime(session.createdAt)} - Expire le ${_formatDateTime(session.expiresAt)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _DangerPanelButton(
                label: pending ? 'Suppression...' : 'Supprimer',
                icon: Icons.delete_outline,
                onPressed: pending ? null : onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fallback(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  return value;
}

String _formatRole(AuthRole? role) {
  return switch (role) {
    AuthRole.admin => 'ADMIN',
    AuthRole.user => 'USER',
    null => 'Non disponible',
  };
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Non disponible';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
