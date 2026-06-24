import 'package:flutter/material.dart';

import 'app_loading_overlay.dart';

/// Returns responsive horizontal/vertical padding for screen-level content.
/// Tighter on narrow viewports (mobile/tablet), standard on desktop.
EdgeInsets screenPadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 480) return const EdgeInsets.symmetric(horizontal: 14, vertical: 16);
  if (w < 720) return const EdgeInsets.symmetric(horizontal: 18, vertical: 20);
  return const EdgeInsets.all(24);
}

/// Page title row inside the body: title on left, actions on right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.title = '',
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final hasTitle = title.isNotEmpty || subtitle != null;
    final titleWidget = hasTitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              if (subtitle != null) ...[
                if (title.isNotEmpty) const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ],
          )
        : null;

    if (actions.isEmpty) {
      return titleWidget ?? const SizedBox.shrink();
    }

    if (!hasTitle) {
      return Align(
        alignment: Alignment.centerRight,
        child: Wrap(spacing: 8, runSpacing: 8, children: actions),
      );
    }

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget!,
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleWidget!),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

/// Standard responsive screen scaffold.
/// [title] and [actions] render inside the body below the app profile bar.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.spacing = 18,
    this.loading = false,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final double spacing;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final hasPageHeader =
        (title != null && title!.isNotEmpty) ||
        subtitle != null ||
        actions.isNotEmpty;

    return Padding(
      padding: screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPageHeader)
                  ScreenHeader(
                    title: title ?? '',
                    subtitle: subtitle,
                    actions: actions,
                  ),
                if (hasPageHeader) SizedBox(height: spacing),
                Expanded(
                  child: AppLoadingOverlay(isLoading: loading, child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
