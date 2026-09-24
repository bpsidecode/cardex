import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.name,
    required this.collected,
    this.size = 44,
  });

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
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: size * .42,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
