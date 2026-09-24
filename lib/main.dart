import 'package:flutter/material.dart' hide Badge;

import 'models/catalog_models.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/progress_repository.dart';
import 'services/collection_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardexBootstrap());
}

class CardexBootstrap extends StatefulWidget {
  const CardexBootstrap({super.key});
  @override
  State<CardexBootstrap> createState() => _CardexBootstrapState();
}

class _CardexBootstrapState extends State<CardexBootstrap> {
  late final CollectionService service;
  @override
  void initState() {
    super.initState();
    service =
        CollectionService(BundledCatalogRepository(), LocalProgressRepository())
          ..initialize();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: service,
        builder: (_, __) => MaterialApp(
          title: 'Cardex',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              colorSchemeSeed: const Color(0xff0b6656),
              brightness: Brightness.light,
              useMaterial3: true),
          darkTheme: ThemeData(
              colorSchemeSeed: const Color(0xff62d9bd),
              brightness: Brightness.dark,
              useMaterial3: true),
          themeMode: ThemeMode.system,
          home: service.ready
              ? HomeScreen(service: service)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator())),
        ),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});
  final CollectionService service;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      DiscoverPage(service: widget.service),
      ExplorePage(service: widget.service),
      CollectionPage(service: widget.service)
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium),
              label: 'Collection'),
        ],
      ),
    );
  }
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.service});
  final CollectionService service;
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

enum _BrandSort {
  alphabetical('Alphabetical'),
  country('Country of origin'),
  parentCompany('Parent company');

  const _BrandSort(this.label);
  final String label;
}

class _DiscoverPageState extends State<DiscoverPage> {
  String query = '';
  _BrandSort sort = _BrandSort.alphabetical;

  int compareBrands(CarBrand a, CarBrand b) {
    final catalog = widget.service.catalog;
    final comparison = switch (sort) {
      _BrandSort.alphabetical => 0,
      _BrandSort.country => catalog
          .country(a.originCountryId)
          .name
          .compareTo(catalog.country(b.originCountryId).name),
      _BrandSort.parentCompany =>
        catalog.group(a.groupId).name.compareTo(catalog.group(b.groupId).name),
    };
    return comparison != 0 ? comparison : a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.service.catalog.brands
        .where(
            (brand) => brand.name.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort(compareBrands);
    return Column(children: [
      const _PageTitle(title: 'Discover', subtitle: 'What did you spot today?'),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchBar(
            hintText: 'Search car brands',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => query = value),
          )),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<_BrandSort>(
            tooltip: 'Sort brands',
            initialValue: sort,
            onSelected: (value) => setState(() => sort = value),
            itemBuilder: (_) => _BrandSort.values
                .map((value) => CheckedPopupMenuItem(
                      value: value,
                      checked: sort == value,
                      child: Text(value.label),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sort),
                const SizedBox(width: 8),
                Text('Sort: ${sort.label}'),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
        ),
      ),
      Expanded(
          child: ListView.separated(
        itemCount: brands.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => BrandTile(
            brand: brands[i],
            service: widget.service,
            showParentCompany: sort == _BrandSort.parentCompany),
      )),
    ]);
  }
}

class BrandTile extends StatelessWidget {
  const BrandTile(
      {super.key,
      required this.brand,
      required this.service,
      this.showParentCompany = false});
  final CarBrand brand;
  final CollectionService service;
  final bool showParentCompany;
  @override
  Widget build(BuildContext context) {
    final collected = service.isCollected(brand.id);
    final country = service.catalog.country(brand.originCountryId);
    return ListTile(
      leading: BrandMark(name: brand.name, collected: collected),
      title: Text(brand.name),
      subtitle: Text(showParentCompany
          ? service.catalog.group(brand.groupId).name
          : '${country.flag} ${country.name} · ${brand.foundedYear}'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BrandDetailPage(brand: brand, service: service))),
      trailing: IconButton(
        tooltip: collected ? 'Remove ${brand.name}' : 'Collect ${brand.name}',
        icon: Icon(collected ? Icons.check_circle : Icons.add_circle_outline,
            color: collected ? Theme.of(context).colorScheme.primary : null),
        onPressed: () async {
          if (collected) {
            await service.toggle(brand);
            return;
          }

          await service.toggle(brand);
          if (!context.mounted) return;
          await _showNewFindCelebration(
            context,
            brand: brand,
            service: service,
          );
        },
      ),
    );
  }
}

Future<void> _showNewFindCelebration(
  BuildContext context, {
  required CarBrand brand,
  required CollectionService service,
  bool returnToCurrentPage = false,
}) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, __) => _NewFindCelebration(
          brand: brand,
          service: service,
          returnToCurrentPage: returnToCurrentPage,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );

class _NewFindCelebration extends StatefulWidget {
  const _NewFindCelebration({
    required this.brand,
    required this.service,
    required this.returnToCurrentPage,
  });

  final CarBrand brand;
  final CollectionService service;
  final bool returnToCurrentPage;

  @override
  State<_NewFindCelebration> createState() => _NewFindCelebrationState();
}

class _NewFindCelebrationState extends State<_NewFindCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _contentOpacity;

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
    if (widget.returnToCurrentPage) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BrandDetailPage(
          brand: widget.brand,
          service: widget.service,
        ),
      ),
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

class BrandDetailPage extends StatelessWidget {
  const BrandDetailPage(
      {super.key, required this.brand, required this.service});
  final CarBrand brand;
  final CollectionService service;
  @override
  Widget build(BuildContext context) {
    final country = service.catalog.country(brand.originCountryId);
    final group = service.catalog.group(brand.groupId);
    final collected = service.isCollected(brand.id);
    return Scaffold(
      key: Key('brand-detail-${brand.id}'),
      appBar: AppBar(title: Text(brand.name)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(
            child:
                BrandMark(name: brand.name, collected: collected, size: 112)),
        const SizedBox(height: 24),
        Text(brand.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(brand.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        _Fact(
            icon: Icons.calendar_today_outlined,
            label: 'Founded',
            value: '${brand.foundedYear}'),
        _Fact(
            icon: Icons.public_outlined,
            label: 'Brand origin',
            value: '${country.flag} ${country.name}'),
        _Fact(
            icon: Icons.account_tree_outlined,
            label: 'Current parent',
            value: group.name),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: Icon(collected ? Icons.undo : Icons.check),
          label: Text(
              collected ? 'Remove from collection' : 'I spotted ${brand.name}'),
          onPressed: () async {
            if (collected) {
              await service.toggle(brand);
              return;
            }

            await service.toggle(brand);
            if (!context.mounted) return;
            await _showNewFindCelebration(
              context,
              brand: brand,
              service: service,
              returnToCurrentPage: true,
            );
          },
        ),
        if (collected && service.collectedAt(brand.id) != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
                'First collected ${_date(service.collectedAt(brand.id)!)}',
                textAlign: TextAlign.center),
          ),
      ]),
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.service});
  final CollectionService service;
  @override
  Widget build(BuildContext context) {
    final badges = service.catalog.badges.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final makers =
        badges.where((b) => b.kind == BadgeKind.manufacturer).toList();
    final countries = badges.where((b) => b.kind == BadgeKind.country).toList();
    return ListView(children: [
      const _PageTitle(
          title: 'Explore', subtitle: 'Find the brands still on your list.'),
      _SetSection(
          title: 'Manufacturer collections', badges: makers, service: service),
      _SetSection(
          title: 'Country collections', badges: countries, service: service),
    ]);
  }
}

class _SetSection extends StatelessWidget {
  const _SetSection(
      {required this.title, required this.badges, required this.service});
  final String title;
  final List<Badge> badges;
  final CollectionService service;
  @override
  Widget build(BuildContext context) => ExpansionTile(
          key: PageStorageKey(title),
          initiallyExpanded: false,
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('${badges.length} collections'),
          children: [
            ...badges.map((badge) {
              final all = service.brandsForBadge(badge);
              final missing = service.missingForBadge(badge);
              final earned = service.isBadgeEarned(badge);
              return ListTile(
                leading: CircleAvatar(
                    child: Icon(earned
                        ? Icons.workspace_premium
                        : Icons.flag_outlined)),
                title: Text(badge.title),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(earned
                          ? 'Badge earned'
                          : '${missing.length} brand${missing.length == 1 ? '' : 's'} to find'),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                          value: (all.length - missing.length) / all.length),
                    ]),
                isThreeLine: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        SetDetailPage(badge: badge, service: service))),
              );
            }),
          ]);
}

class SetDetailPage extends StatelessWidget {
  const SetDetailPage({super.key, required this.badge, required this.service});
  final Badge badge;
  final CollectionService service;
  @override
  Widget build(BuildContext context) {
    final all = service.brandsForBadge(badge)
      ..sort((a, b) => a.name.compareTo(b.name));
    final missing = service.missingForBadge(badge);
    final earned = service.isBadgeEarned(badge);
    return Scaffold(
        appBar: AppBar(title: Text(badge.title)),
        body: ListView(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Icon(
                    earned
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                    earned
                        ? 'Badge earned!'
                        : '${missing.length} brand${missing.length == 1 ? '' : 's'} still missing',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    '${all.length - missing.length} of ${all.length} collected'),
              ])),
          const Divider(),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(earned ? 'Complete collection' : 'Brands to look for',
                  style: Theme.of(context).textTheme.titleMedium)),
          ...all.map((brand) => BrandTile(brand: brand, service: service)),
        ]));
  }
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.service});
  final CollectionService service;
  @override
  Widget build(BuildContext context) {
    final total = service.catalog.brands.length;
    final earned = service.catalog.badges.where(service.isBadgeEarned).toList();
    final percent = total == 0 ? 0.0 : service.collectedCount / total;
    return ListView(children: [
      const _PageTitle(
          title: 'My collection', subtitle: 'Every sighting counts.'),
      Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text('${service.collectedCount} / $total',
                        style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 4),
                    const Text('brands collected'),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: percent),
                  ])))),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Badges', style: Theme.of(context).textTheme.titleLarge)),
      if (earned.isEmpty)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'Complete a manufacturer or country set to earn your first badge.')),
      ...earned.map((badge) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.workspace_premium)),
          title: Text(badge.title),
          subtitle: const Text('Collection complete'))),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Text('How it works',
              style: Theme.of(context).textTheme.titleLarge)),
      const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
              'When you spot a car brand, add it with one tap. Your collection stays on this device and works offline. Complete every brand in a manufacturer or country set to earn its badge.')),
    ]);
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark(
      {super.key, required this.name, required this.collected, this.size = 44});
  final String name;
  final bool collected;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: collected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest),
        child: Text(name.substring(0, 1).toUpperCase(),
            style:
                TextStyle(fontSize: size * .42, fontWeight: FontWeight.bold)),
      );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge)
      ]));
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value));
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
