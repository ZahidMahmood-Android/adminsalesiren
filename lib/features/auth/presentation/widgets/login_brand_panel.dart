import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LoginBrandPanel extends StatefulWidget {
  const LoginBrandPanel({super.key});

  @override
  State<LoginBrandPanel> createState() => _LoginBrandPanelState();
}

class _LoginBrandPanelState extends State<LoginBrandPanel> {
  var _textVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _textVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.ink),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                opacity: _textVisible ? 1 : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified sale intelligence for your markets.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'A focused control room for brands, offers, reports, and publishing workflows.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
