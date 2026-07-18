part of '../match_detail_screen.dart';

class _MatchOddsPanel extends StatelessWidget {
  const _MatchOddsPanel({
    required this.fixture,
    required this.odds,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final RugbyFixture fixture;
  final RugbyMatchOdds? odds;
  final bool loading;
  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = odds;
    final winnerMarket = data?.markets.isNotEmpty == true
        ? data!.markets.first
        : null;
    final hasOdds =
        data != null && data.bookmakersCount > 0 && winnerMarket != null;

    return _MatchDetailSection(
      eyebrow: rugbyFixtureStatus(fixture).isLive
          ? 'Cotes pre-match'
          : 'Avant-match',
      title: 'Favori selon les cotes',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? const _OddsPanelLoading()
            : errorMessage.isNotEmpty
            ? _OddsPanelError(message: errorMessage, onRetry: onRetry)
            : hasOdds
            ? _OddsPanelContent(
                fixture: fixture,
                odds: data,
                winnerMarket: winnerMarket,
              )
            : const _OddsPanelEmpty(),
      ),
    );
  }
}

class _OddsPanelContent extends StatelessWidget {
  const _OddsPanelContent({
    required this.fixture,
    required this.odds,
    required this.winnerMarket,
  });

  final RugbyFixture fixture;
  final RugbyMatchOdds odds;
  final RugbyOddsMarket winnerMarket;

  @override
  Widget build(BuildContext context) {
    final favoriteSide = odds.favorite.side;
    final favoriteLabel = favoriteSide == null
        ? 'Favori indisponible'
        : odds.favorite.teamName ?? _oddsSideLabel(fixture, favoriteSide);
    final showDraw = odds.averages.draw != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x24E63946),
            border: Border.all(color: const Color(0x66E63946)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _confidenceLabel(odds.favorite.confidence),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.grayCool,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        favoriteLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatOdd(odds.favorite.odd),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _OddsAverages(fixture: fixture, averages: odds.averages),
        const SizedBox(height: AppSpacing.md),
        _OddsBookmakerTable(market: winnerMarket, showDraw: showDraw),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cotes fournies a titre informatif. Elles peuvent varier selon les bookmakers.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OddsAverages extends StatelessWidget {
  const _OddsAverages({required this.fixture, required this.averages});

  final RugbyFixture fixture;
  final RugbyOddsAverages averages;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OddsAverageTile(
            label: fixture.teams.home.name ?? 'Domicile',
            value: _formatOdd(averages.home),
          ),
        ),
        if (averages.draw != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OddsAverageTile(
              label: 'Nul',
              value: _formatOdd(averages.draw),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _OddsAverageTile(
            label: fixture.teams.away.name ?? 'Exterieur',
            value: _formatOdd(averages.away),
          ),
        ),
      ],
    );
  }
}

class _OddsAverageTile extends StatelessWidget {
  const _OddsAverageTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grayCool,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OddsBookmakerTable extends StatelessWidget {
  const _OddsBookmakerTable({required this.market, required this.showDraw});

  final RugbyOddsMarket market;
  final bool showDraw;

  @override
  Widget build(BuildContext context) {
    final bookmakers = market.bookmakers.take(4).toList();

    return Column(
      children: [
        _OddsBookmakerRow(
          name: 'Bookmaker',
          home: 'Dom.',
          draw: showDraw ? 'Nul' : null,
          away: 'Ext.',
          header: true,
        ),
        for (final bookmaker in bookmakers)
          _OddsBookmakerRow(
            name: bookmaker.name ?? 'Bookmaker',
            home: _formatOdd(_bookmakerOdd(bookmaker, 'home')),
            draw: showDraw
                ? _formatOdd(_bookmakerOdd(bookmaker, 'draw'))
                : null,
            away: _formatOdd(_bookmakerOdd(bookmaker, 'away')),
          ),
      ],
    );
  }
}

class _OddsBookmakerRow extends StatelessWidget {
  const _OddsBookmakerRow({
    required this.name,
    required this.home,
    required this.away,
    this.draw,
    this.header = false,
  });

  final String name;
  final String home;
  final String? draw;
  final String away;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final color = header ? AppColors.grayCool : AppColors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: header ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: _OddsTableValue(value: home, header: header),
            ),
            if (draw != null)
              Expanded(
                child: _OddsTableValue(value: draw!, header: header),
              ),
            Expanded(
              child: _OddsTableValue(value: away, header: header),
            ),
          ],
        ),
      ),
    );
  }
}

class _OddsTableValue extends StatelessWidget {
  const _OddsTableValue({required this.value, required this.header});

  final String value;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: header ? AppColors.grayCool : AppColors.white,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _OddsPanelLoading extends StatelessWidget {
  const _OddsPanelLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _OddsPanelError extends StatelessWidget {
  const _OddsPanelError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Reessayer',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _OddsPanelEmpty extends StatelessWidget {
  const _OddsPanelEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Aucune cote disponible pour ce match.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.grayCool,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
