import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = DashboardRepository();

  DashboardData? _data;
  String _errorMessage = '';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadDashboard({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _data != null) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final data = await _repository.fetchDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
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
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  void _openRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return AppNavScaffold(
      currentRoute: AppRoutes.dashboard,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboard(fromRefresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: const _DashboardHeader(),
                ),
              ),
              if (_refreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _RefreshStatus(),
                  ),
                ),
              if (_loading && data == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DashboardLoadingState(),
                )
              else if (_errorMessage.isNotEmpty && data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DashboardErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadDashboard(),
                  ),
                )
              else if (data != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (_errorMessage.isNotEmpty)
                          _InlineAlert(message: _errorMessage),
                        _SummaryRow(data: data),
                        const SizedBox(height: AppSpacing.lg),
                        if (!data.hasFavorites)
                          _EmptyDashboard(onOpenRoute: _openRoute)
                        else ...[
                          _FavoritesPreview(data: data),
                          const SizedBox(height: AppSpacing.lg),
                          _UpcomingMatches(
                            matches: data.teamUpcomingMatches,
                            onOpenRoute: _openRoute,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = AuthSessionManager.instance.user;
    final name = user?.username?.isNotEmpty == true
        ? user!.username!
        : user?.email ?? 'Supporter';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accueil', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Dashboard', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Equipes',
            value: data.favorites.teams.total,
            icon: Icons.groups,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Leagues',
            value: data.favorites.competitions.total,
            icon: Icons.emoji_events,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Matchs',
            value: data.teamUpcomingMatches.length,
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Text(
                  animatedValue.toString(),
                  style: textTheme.headlineSmall,
                );
              },
            ),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _FavoritesPreview extends StatelessWidget {
  const _FavoritesPreview({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final competitions = data.favorites.competitions.data.take(4).toList();
    final teams = data.favorites.teams.data.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favoris', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (competitions.isNotEmpty) ...[
          _FavoriteStrip(
            title: 'Championnats',
            favorites: competitions,
            icon: Icons.emoji_events,
            routeBuilder: (favorite) =>
                '${AppRoutes.leagues}/${favorite.entityId}',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (teams.isNotEmpty)
          _FavoriteStrip(
            title: 'Equipes',
            favorites: teams,
            icon: Icons.groups,
            routeBuilder: (favorite) =>
                '${AppRoutes.teams}/${favorite.entityId}',
          ),
      ],
    );
  }
}

class _FavoriteStrip extends StatelessWidget {
  const _FavoriteStrip({
    required this.title,
    required this.favorites,
    required this.icon,
    required this.routeBuilder,
  });

  final String title;
  final List<Favorite> favorites;
  final IconData icon;
  final String Function(Favorite favorite) routeBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            ...favorites.map(
              (favorite) => _FavoriteRow(
                icon: icon,
                label: favorite.entityName ?? favorite.entityId,
                onTap: () => Navigator.of(context).pushNamed(
                  routeBuilder(favorite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 24,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _UpcomingMatches extends StatelessWidget {
  const _UpcomingMatches({
    required this.matches,
    required this.onOpenRoute,
  });

  final List<RugbyFavoriteMatch> matches;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Prochains matchs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => onOpenRoute(AppRoutes.matches),
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (matches.isEmpty)
          const _PanelMessage(
            icon: Icons.event_busy,
            title: 'Aucun prochain match',
            message: 'Ajoute des equipes favorites ou consulte le calendrier.',
          )
        else
          ...matches.map((match) => _MatchCard(match: match)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final RugbyFavoriteMatch match;

  @override
  Widget build(BuildContext context) {
    final fixture = match.nextFixture;
    if (fixture == null) {
      return const SizedBox.shrink();
    }

    final onTap = fixture.id == null
        ? null
        : () => Navigator.of(context).pushNamed(
              '${AppRoutes.matches}/${fixture.id}',
            );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _PressableScale(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RemoteLogo(url: match.logo, icon: Icons.groups),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              _formatKickoff(fixture.date),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FixtureStatusBadge(fixture: fixture),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _TeamName(team: fixture.teams.home)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          _formatScore(fixture.score),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: _TeamName(
                          team: fixture.teams.away,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    fixture.league.name ?? 'Competition',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  const _TeamName({
    required this.team,
    this.textAlign = TextAlign.left,
  });

  final RugbyFixtureTeam team;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      team.name ?? 'Equipe',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _RemoteLogo extends StatelessWidget {
  const _RemoteLogo({
    required this.url,
    required this.icon,
  });

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.white),
        child: SizedBox(
          width: 44,
          height: 44,
          child: imageUrl == null || imageUrl.isEmpty
              ? Icon(icon, color: AppColors.primary)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    icon,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FixtureStatusBadge extends StatelessWidget {
  const _FixtureStatusBadge({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final status = _fixtureStatus(fixture);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.background,
        border: Border.all(color: status.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(color: status.color, pulse: status.isLive),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: status.textColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixtureStatusInfo {
  const _FixtureStatusInfo({
    required this.label,
    required this.color,
    required this.textColor,
    required this.background,
    required this.border,
    this.isLive = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Color background;
  final Color border;
  final bool isLive;
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({
    required this.color,
    required this.pulse,
  });

  final Color color;
  final bool pulse;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.pulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 8, height: 8),
    );

    if (!widget.pulse) {
      return dot;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.82 + (_controller.value * 0.46),
          child: child,
        );
      },
      child: dot,
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _RefreshStatus extends StatelessWidget {
  const _RefreshStatus();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FF4655)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Mise a jour du dashboard...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatefulWidget {
  const _EmptyDashboard({required this.onOpenRoute});

  final ValueChanged<String> onOpenRoute;

  @override
  State<_EmptyDashboard> createState() => _EmptyDashboardState();
}

class _EmptyDashboardState extends State<_EmptyDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelMessage(
      leading: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.94 + (_controller.value * 0.12),
            child: child,
          );
        },
        child: const Icon(
          Icons.star_border,
          color: AppColors.primaryHover,
          size: 36,
        ),
      ),
      title: 'Prepare ton dashboard',
      message: 'Ajoute des championnats et des equipes en favoris.',
      action: AppButton(
        label: 'Parcourir les championnats',
        icon: Icons.emoji_events,
        onPressed: () => widget.onOpenRoute(AppRoutes.leagues),
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.title,
    required this.message,
    this.icon,
    this.leading,
    this.action,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatefulWidget {
  const _DashboardLoadingState();

  @override
  State<_DashboardLoadingState> createState() => _DashboardLoadingStateState();
}

class _DashboardLoadingStateState extends State<_DashboardLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(
                animationValue: _controller.value,
                widthFactor: 0.42,
                height: 20,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SkeletonPanel(animationValue: _controller.value),
              const SizedBox(height: AppSpacing.md),
              _SkeletonPanel(animationValue: _controller.value),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.32,
              height: 22,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.74,
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.56,
              height: 16,
            ),
            const SizedBox(height: AppSpacing.md),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.88,
              height: 14,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.64,
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.animationValue,
    required this.widthFactor,
    required this.height,
  });

  final double animationValue;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final highlight = 0.08 + (animationValue * 0.10);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0x14FFFFFF),
              Color.fromRGBO(255, 255, 255, highlight),
              const Color(0x14FFFFFF),
            ],
            stops: const [0.1, 0.48, 0.9],
          ),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _PanelMessage(
          icon: Icons.error_outline,
          title: 'Dashboard indisponible',
          message: message,
          action: AppButton(
            label: 'Reessayer',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ),
      ),
    );
  }
}

String _formatScore(RugbyFixtureScore score) {
  if (score.home == null || score.away == null) {
    return 'vs';
  }

  return '${score.home} - ${score.away}';
}

String _formatKickoff(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date a venir';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return 'Date a venir';
  }

  final local = kickoff.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}

_FixtureStatusInfo _fixtureStatus(RugbyFixture fixture) {
  if (fixture.score.home != null && fixture.score.away != null) {
    return const _FixtureStatusInfo(
      label: 'Termine',
      color: Color(0xFF22C55E),
      textColor: Color(0xFFC7F7DC),
      background: Color(0x1F3FB984),
      border: Color(0x663FB984),
    );
  }

  final kickoff = fixture.date == null ? null : DateTime.tryParse(fixture.date!);
  final localKickoff = kickoff?.toLocal();
  final now = DateTime.now();
  final isLiveWindow = localKickoff != null &&
      now.isAfter(localKickoff.subtract(const Duration(minutes: 30))) &&
      now.isBefore(localKickoff.add(const Duration(hours: 3, minutes: 30)));

  if (isLiveWindow) {
    return const _FixtureStatusInfo(
      label: 'Live',
      color: AppColors.live,
      textColor: Color(0xFFFECACA),
      background: Color(0x2EE63946),
      border: Color(0x66FF4655),
      isLive: true,
    );
  }

  return const _FixtureStatusInfo(
    label: 'A venir',
    color: Color(0xFFFBBF24),
    textColor: Color(0xFFFDE68A),
    background: Color(0x24FBBF24),
    border: Color(0x66FBBF24),
  );
}
