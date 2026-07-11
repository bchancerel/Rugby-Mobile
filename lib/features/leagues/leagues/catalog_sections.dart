part of '../leagues_screen.dart';

class _MajorLeaguesSection extends StatelessWidget {
  const _MajorLeaguesSection({required this.leagues});

  final List<RugbyLeague> leagues;

  @override
  Widget build(BuildContext context) {
    if (leagues.isEmpty) {
      return _PlainSection(
        title: 'Competitions majeures',
        child: Text(
          'Aucune competition majeure disponible dans le catalogue charge.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grayLight,
              ),
        ),
      );
    }

    return _PlainSection(
      title: 'Competitions majeures',
      child: _LeagueTileGrid(leagues: leagues),
    );
  }
}

class _CountryCatalogSection extends StatelessWidget {
  const _CountryCatalogSection({required this.groups});

  final List<RugbyLeagueCountryGroup> groups;

  @override
  Widget build(BuildContext context) {
    return _PlainSection(
      title: 'Toutes les competitions',
      child: Column(
        children: groups
            .asMap()
            .entries
            .map(
              (group) => Column(
                children: [
                  _CountryGroupBlock(
                    group: group.value,
                    initiallyExpanded: false,
                  ),
                  if (group.key < groups.length - 1)
                    const Divider(
                      height: AppSpacing.lg,
                      thickness: 1,
                      color: Color(0x14FFFFFF),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CountryGroupBlock extends StatefulWidget {
  const _CountryGroupBlock({
    required this.group,
    required this.initiallyExpanded,
  });

  final RugbyLeagueCountryGroup group;
  final bool initiallyExpanded;

  @override
  State<_CountryGroupBlock> createState() => _CountryGroupBlockState();
}

class _CountryGroupBlockState extends State<_CountryGroupBlock> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _CountryGroupBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.countryName != widget.group.countryName) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _CountryMark(
                    countryName: group.countryName,
                    flag: group.flag,
                    code: group.countryCode,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      group.countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CountBadge(count: group.leagues.length),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.grayCool,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _LeagueTileGrid(
                    leagues: group.leagues,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _LeagueTileGrid extends StatelessWidget {
  const _LeagueTileGrid({
    required this.leagues,
  });

  final List<RugbyLeague> leagues;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leagues.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final league = leagues[index];

        return _LeagueTile(league: league);
      },
    );
  }
}

class _LeagueTile extends StatelessWidget {
  const _LeagueTile({required this.league});

  final RugbyLeague league;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0x33020617),
          border: Border.all(color: const Color(0x14FFFFFF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: league.id == null
              ? null
              : () => Navigator.of(context).pushNamed(
                    '${AppRoutes.leagues}/${league.id}',
                  ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LeagueLogo(url: league.logo, size: 80),
                const SizedBox(height: AppSpacing.md),
                Text(
                  league.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlainSection extends StatelessWidget {
  const _PlainSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _CountryMark extends StatelessWidget {
  const _CountryMark({
    required this.countryName,
    required this.flag,
    required this.code,
  });

  final String countryName;
  final String? flag;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final flagUrl = flag;
    final fallback = _countryFallbackMark(countryName, code);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x5C020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          width: 34,
          height: 24,
          child: flagUrl == null
              ? Center(
                  child: Text(
                    fallback,
                    style: const TextStyle(fontSize: 18, height: 1),
                  ),
                )
              : Image.network(
                  flagUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Center(
                      child: Text(
                        fallback,
                        style: const TextStyle(fontSize: 18, height: 1),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

String _countryFallbackMark(String countryName, String? countryCode) {
  final normalizedName = countryName.trim().toLowerCase();
  if (normalizedName == 'world' || normalizedName == 'monde') {
    return '🌍';
  }

  if (normalizedName == 'europe') {
    return '🇪🇺';
  }

  final normalizedCode = countryCode?.trim().toUpperCase();
  if (normalizedCode == null || normalizedCode.length != 2) {
    return '🏳';
  }

  final firstUnit = normalizedCode.codeUnitAt(0);
  final secondUnit = normalizedCode.codeUnitAt(1);
  const asciiA = 0x41;
  const asciiZ = 0x5A;

  if (firstUnit < asciiA ||
      firstUnit > asciiZ ||
      secondUnit < asciiA ||
      secondUnit > asciiZ) {
    return '🏳';
  }

  const regionalIndicatorA = 0x1F1E6;
  return String.fromCharCodes([
    regionalIndicatorA + firstUnit - asciiA,
    regionalIndicatorA + secondUnit - asciiA,
  ]);
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF4655),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: 36,
        height: 28,
        child: Center(
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
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
    final imageUrl = url;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6F8FAFC),
        border: Border.all(color: const Color(0x66FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: imageUrl == null
              ? const Icon(Icons.emoji_events, color: AppColors.slate)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return const Icon(
                      Icons.emoji_events,
                      color: AppColors.slate,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

