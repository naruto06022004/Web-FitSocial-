import 'package:flutter/material.dart';

/// Xếp hạng "cost" bài tập (ước lượng calo / 15 phút — demo).
class ExerciseRankingCostScreen extends StatelessWidget {
  const ExerciseRankingCostScreen({super.key});

  static final List<_ExerciseCost> _rows = [
    _ExerciseCost('Burpees', 12, 'Toàn thân'),
    _ExerciseCost('Chạy bộ (8 km/h)', 11, 'Cardio'),
    _ExerciseCost('Jump rope', 10, 'Cardio'),
    _ExerciseCost('Deadlift', 8, 'Chân + lưng'),
    _ExerciseCost('Squat tạ đòn', 7, 'Chân'),
    _ExerciseCost('Bench press', 6, 'Ngực'),
    _ExerciseCost('Plank', 4, 'Core'),
    _ExerciseCost('Đi bộ nhanh', 4, 'Cardio nhẹ'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [..._rows]..sort((a, b) => b.cost.compareTo(a.cost));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Ranking cost bài tập'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost score',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Điểm ước lượng mức tiêu hao (demo, không thay thế huấn luyện viên). Cao hơn = tốn năng lượng hơn trong ~15 phút.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sorted.asMap().entries.map((e) {
            final rank = e.key + 1;
            final row = e.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank <= 3 ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: rank <= 3 ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(row.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(row.group),
                trailing: Chip(
                  label: Text('${row.cost} cost'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ExerciseCost {
  const _ExerciseCost(this.name, this.cost, this.group);
  final String name;
  final int cost;
  final String group;
}
