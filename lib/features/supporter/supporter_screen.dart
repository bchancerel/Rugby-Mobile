import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_models.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_repository.dart';

class SupporterScreen extends StatefulWidget {
  const SupporterScreen({super.key});

  @override
  State<SupporterScreen> createState() => _SupporterScreenState();
}

class _SupporterScreenState extends State<SupporterScreen> {
  final _repository = SupporterRepository();

  SupporterProfile? _profile;
  String _errorMessage = '';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadProfile({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _profile != null) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final profile = await _repository.fetchProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
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
        _errorMessage = 'Impossible de charger ton profil supporter.';
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return AppNavScaffold(
      currentRoute: AppRoutes.supporter,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadProfile(fromRefresh: true),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _SupporterHeader()),
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
              if (_loading && profile == null)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(child: _SupporterLoadingState()),
                )
              else if (_errorMessage.isNotEmpty && profile == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SupporterErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadProfile(),
                  ),
                )
              else if (profile != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (_errorMessage.isNotEmpty) ...[
                          _InlineAlert(message: _errorMessage),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _AnimatedSupporterSection(
                          index: 0,
                          child: _SupporterLevelPanel(profile: profile),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedSupporterSection(
                          index: 1,
                          child: _SupporterBadgePanel(badges: profile.badges),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedSupporterSection(
                          index: 2,
                          child: _SupporterRecentEventsPanel(
                            events: profile.recentEvents,
                          ),
                        ),
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

class _AnimatedSupporterSection extends StatelessWidget {
  const _AnimatedSupporterSection({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      child: child,
    );
  }
}

class _SupporterHeader extends StatelessWidget {
  const _SupporterHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Text(
        'Mon vestiaire',
        style: textTheme.displayLarge?.copyWith(fontSize: 40),
      ),
    );
  }
}

class _SupporterLevelPanel extends StatelessWidget {
  const _SupporterLevelPanel({required this.profile});

  final SupporterProfile profile;

  @override
  Widget build(BuildContext context) {
    final level = profile.level;
    final nextLevelXp = level.nextLevelXp;
    final nextLevelLabel = level.nextLevelLabel ?? 'Niveau maximum';
    final nextLevelXpLabel = nextLevelXp == null ? 'Max' : '$nextLevelXp XP';

    return _SupporterPanel(
      title: level.label,
      eyebrow: 'Niveau ${level.value}',
      trailing: '${profile.totalXp} XP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GaugeMetaLabel('${level.currentLevelXp} XP'),
              _GaugeMetaLabel(nextLevelXpLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SupporterProgressBar(progress: level.progress),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${level.progress}% vers $nextLevelLabel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _SupporterProgressBar extends StatelessWidget {
  const _SupporterProgressBar({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x1AFFFFFF)),
        child: SizedBox(
          height: 14,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: progress.clamp(0, 100).toDouble() / 100,
            ),
            duration: const Duration(milliseconds: 920),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryHover,
                    Color(0xFF9AF2C2),
                  ],
                  stops: [0, 0.54, 1],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugeMetaLabel extends StatelessWidget {
  const _GaugeMetaLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _SupporterBadgePanel extends StatelessWidget {
  const _SupporterBadgePanel({required this.badges});

  final List<SupporterBadge> badges;

  @override
  Widget build(BuildContext context) {
    final unlockedCount = badges.where((badge) => badge.unlocked).length;

    return _SupporterPanel(
      title: 'Collection',
      eyebrow: 'Badges',
      trailing: '$unlockedCount/${badges.length}',
      child: badges.isEmpty
          ? const _EmptyPanelMessage(
              message: 'Tes prochains badges apparaitront ici.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 380;

                if (!useTwoColumns) {
                  return Column(
                    children: badges
                        .map(
                          (badge) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _SupporterBadgeCard(
                              badge: badge,
                              compact: true,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    return _SupporterBadgeCard(badge: badges[index]);
                  },
                );
              },
            ),
    );
  }
}

class _SupporterBadgeCard extends StatelessWidget {
  const _SupporterBadgeCard({
    required this.badge,
    this.compact = false,
  });

  final SupporterBadge badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final opacity = badge.unlocked ? 1.0 : 0.52;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x57020617),
          border: Border.all(
            color: badge.unlocked
                ? const Color(0x3DFBBF24)
                : const Color(0x1AFFFFFF),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: compact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BadgeMark(badgeKey: badge.key, unlocked: badge.unlocked),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            badge.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.grayLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${badge.xp} XP bonus',
                            style: textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF9AF2C2),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BadgeMark(badgeKey: badge.key, unlocked: badge.unlocked),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      badge.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        badge.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${badge.xp} XP bonus',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9AF2C2),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SupporterRecentEventsPanel extends StatelessWidget {
  const _SupporterRecentEventsPanel({required this.events});

  final List<SupporterEvent> events;

  @override
  Widget build(BuildContext context) {
    return _SupporterPanel(
      title: 'Derniers points',
      eyebrow: 'Activite',
      trailing: events.length.toString(),
      child: events.isEmpty
          ? const _EmptyPanelMessage(
              message: 'Les prochaines actions supporter apparaitront ici.',
            )
          : Column(
              children: events
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SupporterEventCard(event: event),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SupporterEventCard extends StatelessWidget {
  const _SupporterEventCard({required this.event});

  final SupporterEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x57020617),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x243FB984),
                border: Border.all(color: const Color(0x523FB984)),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.add_task,
                  color: Color(0xFF9AF2C2),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventLabel(event.type),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatEventDate(event.createdAt),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.grayCool,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '+${event.xp} XP',
              style: textTheme.labelLarge?.copyWith(
                color: const Color(0xFF9AF2C2),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeMark extends StatelessWidget {
  const _BadgeMark({
    required this.badgeKey,
    required this.unlocked,
  });

  final String badgeKey;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final assetPath = _badgeAssetPath(badgeKey);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x24FBBF24),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x3DFBBF24)),
      ),
      child: SizedBox(
        width: 68,
        height: 68,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: assetPath == null
              ? Icon(
                  unlocked ? Icons.workspace_premium : Icons.lock_outline,
                  color: const Color(0xFFFDE68A),
                  size: 30,
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    unlocked ? Icons.workspace_premium : Icons.lock_outline,
                    color: const Color(0xFFFDE68A),
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SupporterPanel extends StatelessWidget {
  const _SupporterPanel({
    required this.title,
    required this.child,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? eyebrow;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(title, style: textTheme.titleMedium),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    trailing!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF9AF2C2),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
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
              'Mise a jour supporter...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FF4655)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _SupporterLoadingState extends StatelessWidget {
  const _SupporterLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonPanel(height: 156),
        SizedBox(height: AppSpacing.lg),
        _SkeletonPanel(height: 360),
      ],
    );
  }
}

class _SupporterErrorState extends StatelessWidget {
  const _SupporterErrorState({
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
        child: _SupporterPanel(
          title: 'Supporter indisponible',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Reessayer',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
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

class _SkeletonPanel extends StatefulWidget {
  const _SkeletonPanel({required this.height});

  final double height;

  @override
  State<_SkeletonPanel> createState() => _SkeletonPanelState();
}

class _SkeletonPanelState extends State<_SkeletonPanel>
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x7A020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.28,
                    height: 12,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.62,
                    height: 22,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 1,
                    height: 14,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.72,
                    height: 14,
                  ),
                ],
              );
            },
          ),
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

String? _badgeAssetPath(String badgeKey) {
  return switch (badgeKey) {
    'FIRST_FAVORITE' => 'assets/images/badges/badge_1.png',
    'CALENDAR_SUBSCRIBER' => 'assets/images/badges/badge_2.png',
    'MATCH_DAY' => 'assets/images/badges/badge_3.png',
    'FINISHER' => 'assets/images/badges/badge_4.png',
    'LOYAL_SUPPORTER' => 'assets/images/badges/badge_5.png',
    'EXPLORER' => 'assets/images/badges/badge_6.png',
    'DERBY_HUNTER' => 'assets/images/badges/badge_7.png',
    'LIVE_REGULAR' => 'assets/images/badges/badge_8.png',
    'MATCH_ARCHIVIST' => 'assets/images/badges/badge_9.png',
    'TEAM_SCOUT' => 'assets/images/badges/badge_10.png',
    'COMPETITION_TOUR' => 'assets/images/badges/badge_11.png',
    'SUPER_FAVORITE' => 'assets/images/badges/badge_12.png',
    _ => null,
  };
}

String _eventLabel(String type) {
  return switch (type) {
    'FAVORITE_TEAM_ADDED' => 'Equipe favorite ajoutee',
    'FAVORITE_CLUB_ADDED' => 'Club favori ajoute',
    'FAVORITE_COMPETITION_ADDED' => 'Competition favorite ajoutee',
    'MATCH_VIEWED' => 'Fiche match consultee',
    'LIVE_MATCH_FOLLOWED' => 'Match live suivi',
    'FINISHED_MATCH_VIEWED' => 'Match termine consulte',
    'PROFILE_COMPLETED' => 'Profil complete',
    'DAILY_ACTIVE' => 'Jour actif',
    'TEAM_VIEWED' => 'Equipe visitee',
    'COMPETITION_VIEWED' => 'Championnat visite',
    'BADGE_UNLOCKED' => 'Badge debloque',
    _ => type,
  };
}

String _formatEventDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}
