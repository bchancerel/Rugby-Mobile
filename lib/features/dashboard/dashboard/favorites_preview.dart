part of 'package:rugby_jam_mobile/features/dashboard/dashboard_screen.dart';

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

