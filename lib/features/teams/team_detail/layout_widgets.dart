part of '../team_detail_screen.dart';

class _TeamPanelMessage extends StatelessWidget {
  const _TeamPanelMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.redAccent, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w700,
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

class _TeamDetailHeader extends StatelessWidget {
  const _TeamDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            navigator.pushReplacementNamed(AppRoutes.dashboard);
          },
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xA6020617),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _TeamLeagueContextGroup {
  const _TeamLeagueContextGroup({required this.contexts});

  final List<RugbyTeamContext> contexts;

  RugbyTeamLeague get league => contexts.first.league;
}

class _TeamContextSelector extends StatelessWidget {
  const _TeamContextSelector({
    required this.groups,
    required this.selectedContext,
    required this.selectedLeagueGroup,
    required this.onLeagueSelected,
    required this.onSeasonSelected,
  });

  final List<_TeamLeagueContextGroup> groups;
  final RugbyTeamContext selectedContext;
  final _TeamLeagueContextGroup? selectedLeagueGroup;
  final ValueChanged<int> onLeagueSelected;
  final ValueChanged<int> onSeasonSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.redAccent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Championnat et saison',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _TeamContextDropdown<int>(
              label: 'Championnat',
              value: selectedContext.league.id,
              items: groups
                  .map(
                    (group) => DropdownMenuItem<int>(
                      value: group.league.id!,
                      child: Text(group.league.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (leagueId) {
                if (leagueId != null) {
                  onLeagueSelected(leagueId);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _TeamContextDropdown<int>(
              label: 'Saison',
              value: selectedContext.league.season,
              items: (selectedLeagueGroup?.contexts ?? const <RugbyTeamContext>[])
                  .map(
                    (context) => DropdownMenuItem<int>(
                      value: context.league.season!,
                      child: Text(
                        '${context.league.season} - ${context.fixturesCount} matchs',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (season) {
                if (season != null) {
                  onSeasonSelected(season);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamContextDropdown<T> extends StatelessWidget {
  const _TeamContextDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grayCool,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: items.any((item) => item.value == value)
                      ? value
                      : null,
                  isExpanded: true,
                  dropdownColor: AppColors.night,
                  iconEnabledColor: AppColors.white,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  items: items,
                  onChanged: items.isEmpty ? null : onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({
    required this.context,
    required this.favorite,
    required this.favoriteLimit,
    required this.favoriteCount,
    required this.favoritePending,
    required this.onToggleFavorite,
  });

  final RugbyTeamContext context;
  final Favorite? favorite;
  final int favoriteLimit;
  final int favoriteCount;
  final bool favoritePending;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext buildContext) {
    final favoriteActive = favorite != null;
    final limitReached = !favoriteActive && favoriteCount >= favoriteLimit;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xE6020617), Color(0xF0111827), Color(0xCC7F1D2D)],
          ),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _TeamLogo(url: context.team.logo),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.team.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(buildContext).textTheme.headlineSmall
                          ?.copyWith(
                            fontFamily: 'RugbyJamImpact',
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${context.league.displayName} / Saison ${context.league.season}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(buildContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: AppColors.grayCool,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (context.league.id != null &&
                            context.league.season != null)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(buildContext).pushNamed(
                                '${AppRoutes.leagues}/${context.league.id}?season=${context.league.season}',
                              );
                            },
                            icon: const Icon(Icons.emoji_events, size: 18),
                            label: const Text('Voir le championnat'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.white,
                              backgroundColor: const Color(0xA6020617),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              textStyle: Theme.of(buildContext)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        _TeamFavoriteButton(
                          active: favoriteActive,
                          pending: favoritePending,
                          limitReached: limitReached,
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamFavoriteButton extends StatelessWidget {
  const _TeamFavoriteButton({
    required this.active,
    required this.pending,
    required this.limitReached,
    required this.onPressed,
  });

  final bool active;
  final bool pending;
  final bool limitReached;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = active
        ? 'Retirer des favoris'
        : limitReached
        ? 'Limite de favoris atteinte'
        : 'Ajouter aux favoris';

    return TextButton.icon(
      onPressed: pending ? null : onPressed,
      icon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Icon(active ? Icons.star : Icons.star_border),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: active ? const Color(0xFFFFD166) : AppColors.white,
        disabledForegroundColor: AppColors.grayCool,
        backgroundColor: const Color(0xA6020617),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return SizedBox(
      width: 72,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: imageUrl == null
            ? const Icon(Icons.shield_outlined, color: AppColors.red, size: 42)
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.shield_outlined,
                    color: AppColors.red,
                    size: 42,
                  );
                },
              ),
      ),
    );
  }
}
