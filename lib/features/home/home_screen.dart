import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/assets/app_assets.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_logo.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _competitions = [
    _Competition('Top 14', AppAssets.competitionTop14),
    _Competition('Six Nations', AppAssets.competitionSixNations),
    _Competition('Rugby Championship', AppAssets.competitionRugbyChampionship),
    _Competition('Champions Cup', AppAssets.competitionChampionsCup),
    _Competition('Challenge Cup', AppAssets.competitionChallengeCup),
    _Competition('United Rugby Championship', AppAssets.competitionUrc),
    _Competition('Super Rugby Pacific', AppAssets.competitionSuperRugby),
    _Competition('Pro D2', AppAssets.competitionProD2),
    _Competition('Major League Rugby', AppAssets.competitionMajorLeague),
    _Competition('Rugby World Cup', AppAssets.competitionWorldCup),
  ];

  @override
  Widget build(BuildContext context) {
    if (AuthSessionManager.instance.isAuthenticated) {
      return const _AuthenticatedHomeScreen();
    }

    final viewportHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: viewportHeight,
                  child: const _HeroSection(),
                ),
              ),
              const SliverToBoxAdapter(
                child: _CompetitionCarousel(competitions: _competitions),
              ),
              const SliverToBoxAdapter(child: _FeatureGridSection()),
              const SliverToBoxAdapter(child: _SupporterSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 128)),
            ],
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              top: false,
              child: _StickyLoginButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedHomeScreen extends StatefulWidget {
  const _AuthenticatedHomeScreen();

  @override
  State<_AuthenticatedHomeScreen> createState() =>
      _AuthenticatedHomeScreenState();
}

class _AuthenticatedHomeScreenState extends State<_AuthenticatedHomeScreen> {
  bool _pending = false;

  Future<void> _logout() async {
    setState(() {
      _pending = true;
    });

    try {
      await AuthSessionManager.instance.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _pending ? 'Deconnexion...' : 'Se deconnecter',
                icon: Icons.logout,
                onPressed: _pending ? null : _logout,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.homeHero,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xF507111D),
                Color(0xC707111D),
                Color(0xF207111D),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HomeBrand(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RugbyJam',
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'LE RUGBY, PARTOUT, FACILEMENT',
                  style: textTheme.displayLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Retrouve tous les résultats, classements et statistiques de tes compétitions de rugby préférées en un seul endroit.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 136),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompetitionCarousel extends StatefulWidget {
  const _CompetitionCarousel({required this.competitions});

  final List<_Competition> competitions;

  @override
  State<_CompetitionCarousel> createState() => _CompetitionCarouselState();
}

class _CompetitionCarouselState extends State<_CompetitionCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserTouching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startAutoScroll() async {
    while (mounted) {
      if (!mounted || !_scrollController.hasClients || _isUserTouching) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        continue;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final remaining = maxScroll - _scrollController.offset;

      if (remaining <= 1) {
        _scrollController.jumpTo(0);
        continue;
      } else {
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: (remaining * 18).round()),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loopedCompetitions = [
      ...widget.competitions,
      ...widget.competitions,
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.appBackground),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Compétitions', style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Les grands rendez-vous rugby',
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 170,
              child: Listener(
                onPointerDown: (_) {
                  _isUserTouching = true;
                },
                onPointerUp: (_) {
                  _isUserTouching = false;
                },
                onPointerCancel: (_) {
                  _isUserTouching = false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: loopedCompetitions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _CompetitionCard(
                      competition: loopedCompetitions[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.competition});

  final _Competition competition;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Image.asset(
                  competition.asset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            competition.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grayLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGridSection extends StatelessWidget {
  const _FeatureGridSection();

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      title: 'Une app pour suivre vite',
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.18,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _FeatureTile(Icons.flash_on, 'Live', 'Scores et temps forts'),
          _FeatureTile(Icons.star, 'Favoris', 'Tes équipes en premier'),
          _FeatureTile(Icons.leaderboard, 'Classements', 'Lecture claire'),
          _FeatureTile(Icons.query_stats, 'Stats', 'Les chiffres utiles'),
        ],
      ),
    );
  }
}

class _SupporterSection extends StatelessWidget {
  const _SupporterSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _SectionBlock(
      title: 'Mode supporter',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Badges et progression', style: textTheme.titleMedium),
                  const Spacer(),
                  const _LiveDot(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Suis tes équipes, débloque des badges et construis ton profil rugby au fil de la saison.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  _BadgePreview(AppAssets.badgeOne),
                  SizedBox(width: AppSpacing.sm),
                  _BadgePreview(AppAssets.badgeTwo),
                  SizedBox(width: AppSpacing.sm),
                  _BadgePreview(AppAssets.badgeThree),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.appBackground),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(this.icon, this.title, this.label);

  final IconData icon;
  final String title;
  final String label;

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.appBackground,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.82 + (_controller.value * 0.28),
          child: child,
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.live,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x99FF4655),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBrand extends StatelessWidget {
  const _HomeBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: AppLogo(size: 64),
        ),
      ],
    );
  }
}

class _StickyLoginButton extends StatefulWidget {
  const _StickyLoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_StickyLoginButton> createState() => _StickyLoginButtonState();
}

class _StickyLoginButtonState extends State<_StickyLoginButton> {
  bool _isPressed = false;

  Future<void> _handlePressed() async {
    setState(() {
      _isPressed = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    setState(() {
      _isPressed = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (mounted) {
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: const Color(0xEE07111D),
          border: Border.all(
            color: _isPressed ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? const Color(0x88E63946)
                  : const Color(0x66000000),
              blurRadius: _isPressed ? 28 : 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppButton(
            label: 'Se connecter',
            icon: Icons.login,
            onPressed: _handlePressed,
          ),
        ),
      ),
    );
  }
}

class _Competition {
  const _Competition(this.name, this.asset);

  final String name;
  final String asset;
}
