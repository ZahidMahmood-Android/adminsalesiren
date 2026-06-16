import 'package:flutter/material.dart';

/// Returns responsive horizontal/vertical padding for screen-level content.
/// Tighter on narrow viewports (mobile/tablet), standard on desktop.
EdgeInsets screenPadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 480) return const EdgeInsets.symmetric(horizontal: 14, vertical: 16);
  if (w < 720) return const EdgeInsets.symmetric(horizontal: 18, vertical: 20);
  return const EdgeInsets.all(24);
}

/// Responsive page header: title on left, actions on right.
/// On narrow screens the actions flow below the title using [Wrap].
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ],
    );

    if (actions.isEmpty) return titleWidget;

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleWidget),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

/// Standard responsive screen scaffold: padding + header + scrollable body.
/// Callers pass [header] and the already-built [body] (usually from `.when()`).
/// Set [loading] to show a slim progress bar below the header during async work.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.header,
    required this.child,
    this.spacing = 18,
    this.loading = false,
  });

  final Widget header;
  final Widget child;
  final double spacing;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: loading ? 8 : spacing),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
