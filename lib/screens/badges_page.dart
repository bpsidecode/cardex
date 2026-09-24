import 'package:flutter/material.dart';

import '../services/collection_service.dart';
import '../ui/cardex_colors.dart';
import '../widgets/page_title.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key, required this.service});

  final CollectionService service;

  @override
  Widget build(BuildContext context) {
    final total = service.catalog.brands.length;
    final earned = service.catalog.badges.where(service.isBadgeEarned).toList();
    final percent = total == 0 ? 0.0 : service.collectedCount / total;
    return ListView(
      children: [
        const PageTitle(
          title: 'My badges',
          subtitle: 'Every sighting counts.',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${service.collectedCount} / $total',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  const Text('brands collected'),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: percent),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Earned badges',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (earned.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Complete a manufacturer or country set to earn your first badge.',
            ),
          ),
        ...earned.map(
          (badge) => ListTile(
            leading: CircleAvatar(
              key: Key('earned-badge-icon-${badge.id}'),
              backgroundColor: badgeGold,
              foregroundColor: onBadgeGold,
              child: const Icon(Icons.workspace_premium),
            ),
            title: Text(badge.title),
            subtitle: Text(
              'Collection complete',
              key: Key('earned-badge-status-${badge.id}'),
              style: const TextStyle(color: badgeGoldText),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Text(
            'How it works',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
            'When you spot a car brand, add it with one tap. Your collection stays on this device and works offline. Complete every brand in a manufacturer or country set to earn its badge.',
          ),
        ),
      ],
    );
  }
}
