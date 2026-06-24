import 'package:flutter/material.dart';

/// Hosts a [ListTile], [SwitchListTile], or [CheckboxListTile] on its own
/// transparent [Material] so ink splashes and hover states stay visible when
/// the tile sits inside a colored [DecoratedBox], [Card], or [Container].
class AppListTileMaterial extends StatelessWidget {
  const AppListTileMaterial({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(type: MaterialType.transparency, child: child);
  }
}
