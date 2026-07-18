part of '../team_detail_screen.dart';

class _TeamFavoritesLoadResult {
  const _TeamFavoritesLoadResult({this.favorites, this.errorMessage = ''});

  final FavoritesResponse? favorites;
  final String errorMessage;
}

class _TeamContextDetails extends StatelessWidget {
  const _TeamContextDetails({
    required this.loading,
    required this.errorMessage,
    required this.statistics,
    required this.fixtures,
    required this.onRetry,
  });

  final bool loading;
  final String errorMessage;
  final RugbyTeamStatistics? statistics;
  final List<RugbyFixture> fixtures;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Column(
        children: [
          AppSkeletonBlock(height: 180),
          SizedBox(height: AppSpacing.md),
          AppSkeletonBlock(height: 220),
        ],
      );
    }

    if (errorMessage.isNotEmpty) {
      return Column(
        children: [
          AppInlineAlert(message: errorMessage),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Reessayer',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TeamStatisticsSection(statistics: statistics),
        const SizedBox(height: AppSpacing.md),
        _TeamFixturesSection(fixtures: fixtures),
      ],
    );
  }
}
