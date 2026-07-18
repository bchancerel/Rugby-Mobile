import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_models.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_repository.dart';

part 'supporter/overview_widgets.dart';
part 'supporter/recent_events.dart';
part 'supporter/shared_widgets.dart';
part 'supporter/state_widgets.dart';
part 'supporter/helpers.dart';

class SupporterScreen extends StatefulWidget {
  const SupporterScreen({super.key});

  @override
  State<SupporterScreen> createState() => _SupporterScreenState();
}

class _SupporterScreenState extends State<SupporterScreen> {
  final _repository = SupporterRepository();

  SupporterProfile? _profile;
  String _errorMessage = '';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadProfile({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _profile != null) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final profile = await _repository.fetchProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
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
        _errorMessage = 'Impossible de charger ton profil supporter.';
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
    final profile = _profile;

    return AppNavScaffold(
      currentRoute: AppRoutes.supporter,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadProfile(fromRefresh: true),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _SupporterHeader()),
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
              if (_loading && profile == null)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(child: _SupporterLoadingState()),
                )
              else if (_errorMessage.isNotEmpty && profile == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SupporterErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadProfile(),
                  ),
                )
              else if (profile != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_errorMessage.isNotEmpty) ...[
                        _InlineAlert(message: _errorMessage),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _AnimatedSupporterSection(
                        index: 0,
                        child: _SupporterLevelPanel(profile: profile),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AnimatedSupporterSection(
                        index: 1,
                        child: _SupporterBadgePanel(badges: profile.badges),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AnimatedSupporterSection(
                        index: 2,
                        child: _SupporterRecentEventsPanel(
                          events: profile.recentEvents,
                        ),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
