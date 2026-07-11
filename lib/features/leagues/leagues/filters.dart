part of '../leagues_screen.dart';

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

