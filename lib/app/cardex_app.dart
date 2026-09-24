import 'package:flutter/material.dart';

import '../repositories/catalog_repository.dart';
import '../repositories/progress_repository.dart';
import '../screens/home_screen.dart';
import '../services/collection_service.dart';

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
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xff62d9bd),
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: service.ready
              ? HomeScreen(service: service)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        ),
      );
}
