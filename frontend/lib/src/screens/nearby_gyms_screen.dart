import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../api/api_client.dart';

/// Bản đồ demo + danh sách phòng tập từ API; mở Google Maps để xem thật.
/// Dùng làm `body` trong [FitnetChrome] hoặc trong [Scaffold.body].
class NearbyGymsScreen extends StatefulWidget {
  const NearbyGymsScreen({super.key, required this.api});

  final ApiClient api;

  static const _fbBg = Color(0xFFF0F2F5);

  @override
  State<NearbyGymsScreen> createState() => _NearbyGymsScreenState();
}

class _NearbyGymsScreenState extends State<NearbyGymsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _gyms = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.api.getJson('/api/gyms', auth: false);
      final data = json['data'];
      final list = <Map<String, dynamic>>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item.cast<String, dynamic>()));
          }
        }
      }
      setState(() => _gyms = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/phong+tap+gym+gần+tôi');
    final ok = await url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ')),
      );
    }
  }

  /// Vị trí marker trên “bản đồ” demo (chuẩn hoá quanh khu vực TP.HCM nếu có tọa độ).
  ({double x, double y, String distance}) _pinForIndex(int i, Map<String, dynamic> g) {
    final lat = g['latitude'];
    final lng = g['longitude'];
    if (lat != null && lng != null) {
      final la = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
      final ln = (lng is num) ? lng.toDouble() : double.tryParse(lng.toString());
      if (la != null && ln != null) {
        const minLat = 10.70;
        const maxLat = 10.85;
        const minLng = 106.65;
        const maxLng = 106.75;
        final nx = ((ln - minLng) / (maxLng - minLng)).clamp(0.12, 0.88);
        final ny = (1.0 - ((la - minLat) / (maxLat - minLat))).clamp(0.12, 0.88);
        return (x: nx, y: ny, distance: 'GPS');
      }
    }
    final n = _gyms.length.clamp(1, 99);
    final x = 0.18 + (i % 4) * 0.18;
    final y = 0.22 + ((i * 3) % n) / n * 0.5;
    return (x: x, y: y, distance: '≈ ${1.0 + i * 0.35} km');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const ColoredBox(
        color: NearbyGymsScreen._fbBg,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: NearbyGymsScreen._fbBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      );
    }

    if (_gyms.isEmpty) {
      return ColoredBox(
        color: NearbyGymsScreen._fbBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'Chưa có phòng tập trong hệ thống. Chạy php artisan db:seed trên backend để có dữ liệu mẫu.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openGoogleMaps(context),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Mở Google Maps'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: NearbyGymsScreen._fbBg,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Danh sách từ máy chủ (demo bản đồ; khi có GPS sẽ căn theo bạn).',
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
                      ...List<Widget>.generate(_gyms.length, (i) {
                        final g = _gyms[i];
                        final name = g['name']?.toString() ?? 'Gym';
                        final pin = _pinForIndex(i, g);
                        return Positioned(
                          left: pin.x * w - 18,
                          top: pin.y * h - 36,
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
                                  name,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
          ...List<Widget>.generate(_gyms.length, (i) {
            final g = _gyms[i];
            final name = g['name']?.toString() ?? '—';
            final addr = g['address']?.toString();
            final pin = _pinForIndex(i, g);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.fitness_center),
                ),
                title: Text(name),
                subtitle: Text(
                  [
                    if (addr != null && addr.isNotEmpty) addr,
                    if (pin.distance != 'GPS') pin.distance else 'Theo tọa độ',
                  ].join(' · '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () => _openGoogleMaps(context),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
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
