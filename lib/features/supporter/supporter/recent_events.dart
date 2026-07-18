part of '../supporter_screen.dart';

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
                child: Icon(Icons.add_task, color: Color(0xFF9AF2C2), size: 22),
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
  const _BadgeMark({required this.badgeKey, required this.unlocked});

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
