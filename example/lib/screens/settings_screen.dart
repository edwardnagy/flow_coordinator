import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import '../data/repositories/authentication_repository.dart';

abstract interface class SettingsScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void openRandomBook();
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: const Text('Open random book'),
            onTap: () {
              FlowCoordinator.of<SettingsScreenListener>(
                context,
              ).openRandomBook();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () {
              AuthenticationRepository.instance.logout();
            },
          ),
        ],
      ),
    );
  }
}
