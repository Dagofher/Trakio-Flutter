import 'package:flutter/material.dart';
import 'device_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trakio 🤖'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceSettingsPage(),
                ),
              );
            },
          ),
        ],
        ),
      body: const Center(
        child: Text('Hola, Trakio!' ),
        ),
    );
  }
}