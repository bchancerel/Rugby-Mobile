part of '../league_detail_screen.dart';

class _LeagueDetailHeader extends StatelessWidget {
  const _LeagueDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        88,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(
            AppRoutes.leagues,
          ),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xA6020617),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  const _LeagueHero({required this.overview});

  final RugbyLeagueOverview overview;

  @override
  Widget build(BuildContext context) {
    final standingsCount = overview.standings.fold<int>(
      0,
      (total, group) => total + group.rows.length,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE6020617),
              Color(0xF0111827),
              Color(0xCC7F1D2D),
            ],
          ),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LeagueLogo(url: overview.league.logo, size: 88),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.league.country.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.redAccent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      overview.league.displayName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontFamily: 'RugbyJamImpact',
                                color: AppColors.white,
                                height: 0.9,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xCC8C1020),
                                    offset: Offset(0, 7),
                                  ),
                                ],
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _SummaryPill(
                          label: overview.league.type ?? 'Competition',
                          value: '',
                        ),
                        _SummaryPill(
                          label: overview.season == null
                              ? 'Saison'
                              : 'Saison ${overview.season}',
                          value: '',
                        ),
                        _SummaryPill(
                          label: '$standingsCount equipes',
                          value: '',
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

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? label : '$value $label';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _LeagueLogo extends StatelessWidget {
  const _LeagueLogo({
    required this.url,
    required this.size,
  });

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: url == null
              ? const Icon(
                  Icons.emoji_events,
                  color: AppColors.red,
                  size: 34,
                )
              : Image.network(
                  url!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.emoji_events,
                      color: AppColors.red,
                      size: 34,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.seasons,
    required this.selectedSeason,
    required this.onSelected,
  });

  final List<int> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: AppColors.redAccent,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Saison',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: seasons.contains(selectedSeason) ? selectedSeason : null,
                hint: const Text('Choisir'),
                dropdownColor: AppColors.night,
                iconEnabledColor: AppColors.white,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                items: seasons
                    .map(
                      (season) => DropdownMenuItem<int>(
                        value: season,
                        child: Text(season.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (season) {
                  if (season != null) {
                    onSelected(season);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueDetailTabs extends StatelessWidget {
  const _LeagueDetailTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<_LeagueDetailTab> tabs;
  final _LeagueDetailTab selectedTab;
  final ValueChanged<_LeagueDetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: tabs.map((tab) {
            final selected = selectedTab == tab;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x66E63946),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabLabel(tab),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? AppColors.white : AppColors.grayCool,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _tabLabel(_LeagueDetailTab tab) {
    return switch (tab) {
      _LeagueDetailTab.standings => 'Classement',
      _LeagueDetailTab.matches => 'Matchs',
      _LeagueDetailTab.bracket => 'Tableau',
    };
  }
}

class _LeagueDetailContent extends StatelessWidget {
  const _LeagueDetailContent({
    required this.overview,
    required this.selectedTab,
  });

  final RugbyLeagueOverview overview;
  final _LeagueDetailTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (selectedTab) {
        _LeagueDetailTab.standings => _StandingsSection(overview: overview),
        _LeagueDetailTab.matches => _MatchesSection(
            key: ValueKey('matches-${overview.season ?? 'all'}'),
            fixtures: overview.fixtures,
            rounds: overview.rounds,
          ),
        _LeagueDetailTab.bracket => _BracketSection(
            key: ValueKey('bracket-${overview.season ?? 'all'}'),
            fixtures: overview.fixtures,
            rounds: overview.rounds,
          ),
      },
    );
  }
}

