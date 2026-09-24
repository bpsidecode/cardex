import 'package:flutter/material.dart' hide Badge;

import '../models/catalog_models.dart';
import '../services/collection_service.dart';
import '../ui/cardex_colors.dart';
import '../widgets/brand_mark.dart';

Future<void> collectAndCelebrate(
  NavigatorState navigator, {
  required CarBrand brand,
  required CollectionService service,
  required WidgetBuilder brandDetailBuilder,
  bool returnToCurrentPage = false,
}) async {
  final earnedBefore = service.catalog.badges
      .where(service.isBadgeEarned)
      .map((badge) => badge.id)
      .toSet();

  await service.toggle(brand);
  if (!navigator.mounted) return;

  final newlyEarnedBadges = service.catalog.badges
      .where(
        (badge) =>
            !earnedBefore.contains(badge.id) && service.isBadgeEarned(badge),
      )
      .toList()
    ..sort((a, b) {
      final kindComparison = a.kind.index.compareTo(b.kind.index);
      return kindComparison != 0 ? kindComparison : a.title.compareTo(b.title);
    });

  await navigator.push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) => _NewFindCelebration(
        brand: brand,
        newlyEarnedBadges: newlyEarnedBadges,
        returnToCurrentPage: returnToCurrentPage,
        brandDetailBuilder: brandDetailBuilder,
      ),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}

class _NewFindCelebration extends StatefulWidget {
  const _NewFindCelebration({
    required this.brand,
    required this.newlyEarnedBadges,
    required this.returnToCurrentPage,
    required this.brandDetailBuilder,
  });

  final CarBrand brand;
  final List<Badge> newlyEarnedBadges;
  final bool returnToCurrentPage;
  final WidgetBuilder brandDetailBuilder;

  @override
  State<_NewFindCelebration> createState() => _NewFindCelebrationState();
}

class _NewFindCelebrationState extends State<_NewFindCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _contentOpacity;
  bool _showingBadgeCelebration = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _markScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.elasticOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.58, curve: Curves.easeOut),
    );
    _controller.addStatusListener(_handleAnimationStatus);
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (!_showingBadgeCelebration && widget.newlyEarnedBadges.isNotEmpty) {
      setState(() => _showingBadgeCelebration = true);
      _controller.duration = const Duration(milliseconds: 1600);
      _controller.forward(from: 0);
      return;
    }
    _finishCelebration();
  }

  void _finishCelebration() {
    if (widget.returnToCurrentPage) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.brandDetailBuilder),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_showingBadgeCelebration) {
      return _buildBadgeCelebration(context);
    }
    return Scaffold(
      key: const Key('new-find-celebration'),
      backgroundColor: colors.primaryContainer,
      body: SafeArea(
        child: Semantics(
          liveRegion: true,
          label: '${widget.brand.name} added to your collection',
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _controller.value,
                    color: colors.primary,
                    accentColor: colors.tertiary,
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _markScale,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            BrandMark(
                              name: widget.brand.name,
                              collected: true,
                              size: 136,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                child:
                                    const Icon(Icons.check_rounded, size: 32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'New find!',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.brand.name,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Added to your collection',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.onPrimaryContainer,
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

  Widget _buildBadgeCelebration(BuildContext context) {
    final multiple = widget.newlyEarnedBadges.length > 1;
    return Scaffold(
      key: const Key('badge-earned-celebration'),
      backgroundColor: badgeGoldContainer,
      body: SafeArea(
        child: Semantics(
          liveRegion: true,
          label: multiple
              ? 'Badges earned: ${widget.newlyEarnedBadges.map((badge) => badge.title).join(', ')}'
              : 'Badge earned: ${widget.newlyEarnedBadges.single.title}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _controller.value,
                    color: badgeGold,
                    accentColor: badgeGoldText,
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _contentOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _markScale,
                          child: const CircleAvatar(
                            radius: 68,
                            backgroundColor: badgeGold,
                            foregroundColor: onBadgeGold,
                            child: Icon(Icons.workspace_premium, size: 86),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          multiple ? 'Badges earned!' : 'Badge earned!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: onBadgeGold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.newlyEarnedBadges.map(
                          (badge) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              badge.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: onBadgeGold,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  final double progress;
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 70);
    final burst = Curves.easeOutCubic.transform(progress.clamp(0, 0.75) / 0.75);
    final opacity = (1 - Curves.easeIn.transform(progress)).clamp(0.0, 1.0);
    const directions = <Offset>[
      Offset(-0.86, -0.5),
      Offset(-0.42, -0.9),
      Offset(0.12, -1),
      Offset(0.65, -0.7),
      Offset(0.96, -0.15),
      Offset(0.82, 0.48),
      Offset(0.38, 0.92),
      Offset(-0.2, 0.98),
      Offset(-0.7, 0.7),
      Offset(-1, 0.12),
    ];

    for (var i = 0; i < directions.length; i++) {
      final distance = 100.0 + (i % 3) * 28;
      final point = center + directions[i] * distance * burst;
      final paint = Paint()
        ..color = (i.isEven ? color : accentColor).withValues(alpha: opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = i.isEven ? 7 : 5;
      if (i % 3 == 0) {
        canvas.drawLine(
          point - directions[i] * 9,
          point + directions[i] * 9,
          paint,
        );
      } else {
        canvas.drawCircle(point, i.isEven ? 7.0 : 5.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      accentColor != oldDelegate.accentColor;
}
