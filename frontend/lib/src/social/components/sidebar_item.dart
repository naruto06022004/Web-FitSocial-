import 'package:flutter/material.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.primary : const Color(0xFF334155);
    final bg = selected ? theme.colorScheme.primary.withValues(alpha: 0.10) : Colors.transparent;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (color ?? theme.colorScheme.primary).withValues(alpha: selected ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

