import 'package:flutter/material.dart';

class CreatePostBox extends StatefulWidget {
  const CreatePostBox({
    super.key,
    required this.avatarText,
    required this.placeholder,
    required this.onTapCompose,
  });

  final String avatarText;
  final String placeholder;
  final VoidCallback onTapCompose;

  @override
  State<CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<CreatePostBox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _hover ? 0.06 : 0.03),
            blurRadius: _hover ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHover: (v) => setState(() => _hover = v),
          onTap: widget.onTapCompose,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(widget.avatarText.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      widget.placeholder,
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.edit_square, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

