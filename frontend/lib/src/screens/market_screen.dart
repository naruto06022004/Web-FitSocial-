import 'package:flutter/material.dart';

import '../api/api_client.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Market',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shopping_bag_outlined),
              title: Text('Khu vực bán hàng'),
              subtitle: Text('Chưa tích hợp API market trong bản demo này'),
            ),
          ),
        ],
      ),
    );
  }
}

