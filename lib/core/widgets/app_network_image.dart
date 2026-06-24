import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _ImageFallback(icon: icon);
    }
    return Image.network(
      imageUrl,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) => _ImageFallback(icon: icon),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _ImageFallback(
          icon: icon,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, this.child});

  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child:
            child ?? Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
