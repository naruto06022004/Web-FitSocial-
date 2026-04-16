import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.authorLabel,
    required this.authorAvatarText,
    required this.timeLabel,
    required this.title,
    required this.body,
    required this.likeCount,
    required this.liked,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final String authorLabel;
  final String authorAvatarText;
  final String timeLabel;
  final String title;
  final String body;
  final int likeCount;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final likeColor = widget.liked ? theme.colorScheme.primary : const Color(0xFF334155);

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
            blurRadius: _hover ? 20 : 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHover: (v) => setState(() => _hover = v),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(
                        widget.authorAvatarText.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.authorLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(widget.timeLabel, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'save', child: Text('Save (demo)')),
                        PopupMenuItem(value: 'hide', child: Text('Hide (demo)')),
                      ],
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.title.trim().isNotEmpty)
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.2),
                  ),
                if (widget.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.body,
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF334155), height: 1.35),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionButton(
                      icon: widget.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: 'Like (${widget.likeCount})',
                      color: likeColor,
                      onPressed: widget.onToggleLike,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.mode_comment_outlined,
                      label: 'Comment',
                      onPressed: widget.onComment,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.reply_outlined,
                      label: 'Share',
                      onPressed: widget.onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? const Color(0xFF334155);
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: fg),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF5F7FA),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

