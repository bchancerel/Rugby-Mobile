part of '../user_account_screen.dart';

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
            username: fallbackUserValue(user?.username, 'Non renseigne'),
            email: fallbackUserValue(user?.email, 'Non disponible'),
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
                  value: formatUserRole(user?.role),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoTile(
                  icon: Icons.event_available,
                  label: 'Creation',
                  value: formatUserDate(user?.createdAt),
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

