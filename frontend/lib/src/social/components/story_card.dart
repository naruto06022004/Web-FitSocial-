import 'package:flutter/material.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.avatarText,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Gradient gradient;
  final String? avatarText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: Text(
                      (avatarText ?? '').isEmpty ? '?' : avatarText!.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

