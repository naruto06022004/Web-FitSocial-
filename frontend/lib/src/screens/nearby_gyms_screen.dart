import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bản đồ demo + danh sách phòng tập gần bạn; mở Google Maps để xem thật.
class NearbyGymsScreen extends StatelessWidget {
  const NearbyGymsScreen({super.key});

  static const _fbBg = Color(0xFFF0F2F5);

  static final List<_GymPin> _demoGyms = [
    _GymPin('Fitnet Gym Quận 1', 0.22, 0.38, '≈ 0.8 km'),
    _GymPin('California Fitness', 0.62, 0.28, '≈ 1.2 km'),
    _GymPin('Gym Thể hình 247', 0.48, 0.62, '≈ 1.5 km'),
    _GymPin('Iron Box', 0.75, 0.55, '≈ 2.1 km'),
  ];

  Future<void> _openGoogleMaps(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/phong+tap+gym+gần+tôi');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _fbBg,
      appBar: AppBar(
        title: const Text('Phòng tập gần bạn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Vị trí demo (khi có GPS sẽ căn theo bạn).',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _MapGridPainter()),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFE8F4FC),
                              Colors.blue.shade50.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                      for (final g in _demoGyms)
                        Positioned(
                          left: g.x * w - 18,
                          top: g.y * h - 36,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.red.shade600, size: 36),
                              Container(
                                constraints: const BoxConstraints(maxWidth: 120),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  g.name,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _openGoogleMaps(context),
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.open_in_new, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openGoogleMaps(context),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Mở Google Maps — tìm phòng tập gần tôi'),
          ),
          const SizedBox(height: 16),
          Text('Gợi ý gần bạn', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._demoGyms.map(
            (g) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.fitness_center),
                ),
                title: Text(g.name),
                subtitle: Text('${g.distance} · Đường đi ước lượng'),
                trailing: IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () => _openGoogleMaps(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymPin {
  const _GymPin(this.name, this.x, this.y, this.distance);
  final String name;
  final double x;
  final double y;
  final String distance;
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.blue.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
