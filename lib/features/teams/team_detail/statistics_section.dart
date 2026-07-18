part of '../team_detail_screen.dart';

class _TeamStatisticsSection extends StatelessWidget {
  const _TeamStatisticsSection({required this.statistics});

  final RugbyTeamStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final data = statistics;
    final record = data?.all;

    return _TeamPanel(
      title: 'Statistiques',
      icon: Icons.bar_chart,
      child: record == null
          ? const _TeamPanelMessage(
              icon: Icons.insights,
              title: 'Statistiques indisponibles',
              message: 'Aucune statistique trouvee pour ce contexte.',
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Matchs',
                        value: _formatNullableInt(record.played),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Victoires',
                        value: _formatNullableInt(record.win),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Taux victoire',
                        value: _formatWinRate(record),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Diff points',
                        value: _formatSignedInt(record.pointsDiff),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _TeamPerformanceTable(statistics: data!),
              ],
            ),
    );
  }
}

class _TeamPerformanceTable extends StatelessWidget {
  const _TeamPerformanceTable({required this.statistics});

  final RugbyTeamStatistics statistics;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyStatistic(statistics.all)) {
      return const _TeamPanelMessage(
        icon: Icons.table_chart,
        title: 'Performance indisponible',
        message: 'Les statistiques detaillees ne sont pas encore disponibles.',
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Performance',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (statistics.form != null)
                  Text(
                    'Forme: ${statistics.form}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TeamPerformanceHeader(),
            _TeamPerformanceRow(label: 'Total', record: statistics.all),
            _TeamPerformanceRow(label: 'Domicile', record: statistics.home),
            _TeamPerformanceRow(label: 'Exterieur', record: statistics.away),
          ],
        ),
      ),
    );
  }
}

class _TeamPerformanceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TeamPerformanceGrid(
      cells: [
        _TeamPerformanceCell(
          text: 'Zone',
          color: AppColors.grayCool,
          fontWeight: FontWeight.w900,
        ),
        for (final label in const ['J', 'G', 'N', 'P', '+', '-', 'Diff'])
          _TeamPerformanceCell(
            text: label,
            color: AppColors.grayCool,
            fontWeight: FontWeight.w900,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _TeamPerformanceRow extends StatelessWidget {
  const _TeamPerformanceRow({required this.label, required this.record});

  final String label;
  final RugbyTeamStatisticsRecord record;

  @override
  Widget build(BuildContext context) {
    return _TeamPerformanceGrid(
      cells: [
        _TeamPerformanceCell(text: label),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.played),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.win),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.draw),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.loss),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.pointsFor),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.pointsAgainst),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatSignedInt(record.pointsDiff),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TeamPerformanceGrid extends StatelessWidget {
  const _TeamPerformanceGrid({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 2, child: cells[0]),
          for (final cell in cells.skip(1)) Expanded(child: cell),
        ],
      ),
    );
  }
}

class _TeamPerformanceCell extends StatelessWidget {
  const _TeamPerformanceCell({
    required this.text,
    this.color = AppColors.white,
    this.fontWeight = FontWeight.w800,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: color, fontWeight: fontWeight),
    );
  }
}
