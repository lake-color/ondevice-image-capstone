import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Red-outlined card for states that stop the normal flow: denied permission,
/// failed analysis and empty history. All three share the same layout and
/// differ only in wording and in what the buttons do.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.badge,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
  });

  final String badge;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.outlined(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Text(badge, style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 18),
            Text(message),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
