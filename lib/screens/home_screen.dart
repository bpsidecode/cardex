import 'package:flutter/material.dart';

import '../services/collection_service.dart';
import 'badges_page.dart';
import 'collections_page.dart';
import 'discover_page.dart';

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
      CollectionsPage(service: widget.service),
      BadgesPage(service: widget.service),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Badges',
          ),
        ],
      ),
    );
  }
}
