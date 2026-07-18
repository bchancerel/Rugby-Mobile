part of '../supporter_screen.dart';

class _AnimatedSupporterSection extends StatelessWidget {
  const _AnimatedSupporterSection({required this.index, required this.child});

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grayLight),
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
  const _SupporterBadgeCard({required this.badge, this.compact = false});

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
