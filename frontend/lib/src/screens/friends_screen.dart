import 'package:flutter/material.dart';

import '../api/api_client.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Bạn bè',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Người bạn mẫu'),
              subtitle: Text('Chưa có API bạn bè trong bản demo này'),
            ),
          ),
        ],
      ),
    );
  }
}

