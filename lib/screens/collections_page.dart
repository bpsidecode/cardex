import 'package:flutter/material.dart' hide Badge;

import '../models/catalog_models.dart';
import '../services/collection_service.dart';
import '../ui/cardex_colors.dart';
import '../widgets/page_title.dart';
import 'brand_pages.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key, required this.service});

  final CollectionService service;

  @override
  Widget build(BuildContext context) {
    final badges = service.catalog.badges.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final makers =
        badges.where((badge) => badge.kind == BadgeKind.manufacturer).toList();
    final countries =
        badges.where((badge) => badge.kind == BadgeKind.country).toList();
    return ListView(
      children: [
        const PageTitle(
          title: 'Collections',
          subtitle: 'Find the brands still on your list.',
        ),
        _SetSection(
          title: 'Manufacturer collections',
          badges: makers,
          service: service,
        ),
        _SetSection(
          title: 'Country collections',
          badges: countries,
          service: service,
        ),
      ],
    );
  }
}

class _SetSection extends StatelessWidget {
  const _SetSection({
    required this.title,
    required this.badges,
    required this.service,
  });

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
            final collectedCount = all.length - missing.length;
            final state = service.isBadgeEarned(badge)
                ? _CollectionProgressState.completed
                : collectedCount == 0
                    ? _CollectionProgressState.notStarted
                    : _CollectionProgressState.inProgress;
            final colors = Theme.of(context).colorScheme;
            final statusText = switch (state) {
              _CollectionProgressState.completed => 'Badge earned',
              _CollectionProgressState.inProgress =>
                '${missing.length} brand${missing.length == 1 ? '' : 's'} to find',
              _CollectionProgressState.notStarted =>
                'Not started · ${missing.length} brand${missing.length == 1 ? '' : 's'} to find',
            };
            final statusColor = switch (state) {
              _CollectionProgressState.completed => badgeGoldText,
              _CollectionProgressState.inProgress => null,
              _CollectionProgressState.notStarted => colors.onSurfaceVariant,
            };
            final progressColor = switch (state) {
              _CollectionProgressState.completed => badgeGold,
              _CollectionProgressState.inProgress => colors.primary,
              _CollectionProgressState.notStarted => colors.outline,
            };
            return ListTile(
              key: Key('collection-row-${badge.id}'),
              leading: CircleAvatar(
                key: Key('collection-icon-${badge.id}'),
                backgroundColor: switch (state) {
                  _CollectionProgressState.completed => badgeGold,
                  _CollectionProgressState.inProgress => null,
                  _CollectionProgressState.notStarted =>
                    colors.surfaceContainerHighest,
                },
                foregroundColor: switch (state) {
                  _CollectionProgressState.completed => onBadgeGold,
                  _CollectionProgressState.inProgress => null,
                  _CollectionProgressState.notStarted =>
                    colors.onSurfaceVariant,
                },
                child: Icon(
                  state == _CollectionProgressState.completed
                      ? Icons.workspace_premium
                      : Icons.flag_outlined,
                ),
              ),
              title: Text(badge.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    key: Key('collection-status-${badge.id}'),
                    style: TextStyle(color: statusColor),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    key: Key('collection-progress-${badge.id}'),
                    value: all.isEmpty ? 0 : collectedCount / all.length,
                    color: progressColor,
                    backgroundColor:
                        state == _CollectionProgressState.notStarted
                            ? colors.surfaceContainerHighest
                            : null,
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SetDetailPage(
                    badge: badge,
                    service: service,
                  ),
                ),
              ),
            );
          }),
        ],
      );
}

enum _CollectionProgressState { completed, inProgress, notStarted }
