import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_repository.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final _repository = LeaguesRepository();
  final _searchController = TextEditingController();

  List<RugbyLeague> _leagues = const [];
  String _errorMessage = '';
  String _selectedCountry = '';
  String _selectedType = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _currentSeasonOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLeagues();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _repository.close();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _loadLeagues({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _leagues.isNotEmpty) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final leagues = await _repository.fetchLeagues();

      if (!mounted) {
        return;
      }

      setState(() {
        _leagues = leagues;
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
        _errorMessage = 'Impossible de charger les competitions.';
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
    final hasLeagues = _leagues.isNotEmpty;
    final countryOptions = findLeagueCountryOptions(_leagues);
    final typeOptions = findLeagueTypeOptions(_leagues);
    final selectedCountry =
        countryOptions.contains(_selectedCountry) ? _selectedCountry : '';
    final selectedType = typeOptions.contains(_selectedType) ? _selectedType : '';
    final filteredLeagues = filterLeagues(
      leagues: _leagues,
      query: _searchController.text,
      country: selectedCountry,
      type: selectedType,
      currentSeasonOnly: _currentSeasonOnly,
    );
    final majorLeagues = findMajorLeagues(_leagues);
    final countryGroups = groupLeaguesByCountry(filteredLeagues);

    return AppNavScaffold(
      currentRoute: AppRoutes.leagues,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadLeagues(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _LeaguesHeader(),
              ),
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
              if (_loading && !hasLeagues)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(child: _LeaguesLoadingState()),
                )
              else if (_errorMessage.isNotEmpty && !hasLeagues)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeaguesErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadLeagues(),
                  ),
                )
              else if (!hasLeagues)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeaguesEmptyState(onRetry: () => _loadLeagues()),
                )
              else
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
                        _AnimatedLeagueSection(
                          index: 0,
                          child: _MajorLeaguesSection(leagues: majorLeagues),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedLeagueSection(
                          index: 1,
                          child: _LeaguesSummary(
                            totalLeagues: _leagues.length,
                            filteredCount: filteredLeagues.length,
                            countryCount: countryOptions.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedLeagueSection(
                          index: 2,
                          child: _LeaguesFilters(
                            searchController: _searchController,
                            countryOptions: countryOptions,
                            typeOptions: typeOptions,
                            selectedCountry: selectedCountry,
                            selectedType: selectedType,
                            currentSeasonOnly: _currentSeasonOnly,
                            onCountryChanged: (value) {
                              setState(() {
                                _selectedCountry = value ?? '';
                              });
                            },
                            onTypeChanged: (value) {
                              setState(() {
                                _selectedType = value ?? '';
                              });
                            },
                            onCurrentSeasonChanged: (value) {
                              setState(() {
                                _currentSeasonOnly = value;
                              });
                            },
                            onReset: _resetFilters,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (filteredLeagues.isEmpty)
                          _AnimatedLeagueSection(
                            index: 3,
                            child: _NoFilteredLeagues(onReset: _resetFilters),
                          )
                        else
                          _AnimatedLeagueSection(
                            index: 3,
                            child: _CountryCatalogSection(
                              groups: countryGroups,
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

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedCountry = '';
      _selectedType = '';
      _currentSeasonOnly = false;
    });
  }
}

class _AnimatedLeagueSection extends StatelessWidget {
  const _AnimatedLeagueSection({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      child: child,
    );
  }
}

class _LeaguesHeader extends StatelessWidget {
  const _LeaguesHeader();

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
        'Competitions',
        style: textTheme.displayLarge?.copyWith(fontSize: 40),
      ),
    );
  }
}

class _LeaguesSummary extends StatelessWidget {
  const _LeaguesSummary({
    required this.totalLeagues,
    required this.countryCount,
    required this.filteredCount,
  });

  final int totalLeagues;
  final int countryCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(label: 'Competitions', value: '$totalLeagues'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(label: 'Pays', value: '$countryCount'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(label: 'Filtres', value: '$filteredCount'),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x5C020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.grayCool,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
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

class _LeaguesFilters extends StatefulWidget {
  const _LeaguesFilters({
    required this.searchController,
    required this.countryOptions,
    required this.typeOptions,
    required this.selectedCountry,
    required this.selectedType,
    required this.currentSeasonOnly,
    required this.onCountryChanged,
    required this.onTypeChanged,
    required this.onCurrentSeasonChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final List<String> countryOptions;
  final List<String> typeOptions;
  final String selectedCountry;
  final String selectedType;
  final bool currentSeasonOnly;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<bool> onCurrentSeasonChanged;
  final VoidCallback onReset;

  @override
  State<_LeaguesFilters> createState() => _LeaguesFiltersState();
}

class _LeaguesFiltersState extends State<_LeaguesFilters> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.filter_alt_outlined,
                    color: AppColors.grayCool,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Recherche filtree',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
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
                  child: Column(
                    children: [
                      TextField(
                        controller: widget.searchController,
                        textInputAction: TextInputAction.search,
                        decoration: _fieldDecoration(
                          label: 'Recherche',
                          hint: 'Nom de competition ou pays',
                          icon: Icons.search,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FilterDropdown(
                        label: 'Pays',
                        value: widget.selectedCountry,
                        options: widget.countryOptions,
                        onChanged: widget.onCountryChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FilterDropdown(
                        label: 'Type',
                        value: widget.selectedType,
                        options: widget.typeOptions,
                        onChanged: widget.onTypeChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CurrentSeasonSwitch(
                        value: widget.currentSeasonOnly,
                        onChanged: widget.onCurrentSeasonChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Reinitialiser',
                          icon: Icons.restart_alt,
                          variant: AppButtonVariant.secondary,
                          onPressed: widget.onReset,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (!_expanded && _hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtres actifs',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryHover,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  bool get _hasActiveFilters {
    return widget.searchController.text.trim().isNotEmpty ||
        widget.selectedCountry.isNotEmpty ||
        widget.selectedType.isNotEmpty ||
        widget.currentSeasonOnly;
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? '' : value,
      isExpanded: true,
      decoration: _fieldDecoration(
        label: label,
        icon: label == 'Pays' ? Icons.flag_outlined : Icons.category_outlined,
      ),
      dropdownColor: AppColors.night,
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(label == 'Pays' ? 'Tous les pays' : 'Tous les types'),
        ),
        ...options.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CurrentSeasonSwitch extends StatelessWidget {
  const _CurrentSeasonSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x5C020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryHover,
        contentPadding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.sm,
        ),
        title: Text(
          'Saison actuelle',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

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

class _NoFilteredLeagues extends StatelessWidget {
  const _NoFilteredLeagues({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _LeaguesPanel(
      title: 'Aucun resultat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aucune competition ne correspond a ces filtres.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayLight,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Effacer les filtres',
            icon: Icons.filter_alt_off,
            variant: AppButtonVariant.secondary,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  String? hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: const Color(0x5C020617),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryHover),
    ),
  );
}

class _LeaguesPanel extends StatelessWidget {
  const _LeaguesPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
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
              'Actualisation des competitions...',
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
        color: const Color(0x1AFBBF24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4DFBBF24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _LeaguesLoadingState extends StatelessWidget {
  const _LeaguesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonBlock(height: 86),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 76),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 176),
      ],
    );
  }
}

class _LeaguesErrorState extends StatelessWidget {
  const _LeaguesErrorState({
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
        child: _LeaguesPanel(
          title: 'Competitions indisponibles',
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

class _LeaguesEmptyState extends StatelessWidget {
  const _LeaguesEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _LeaguesPanel(
          title: 'Aucune competition',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "L'API n'a renvoye aucune competition pour le moment.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Actualiser',
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

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x7A020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(height: height, width: double.infinity),
    );
  }
}
