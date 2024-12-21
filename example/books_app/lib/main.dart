import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import 'flow/authenticated/authenticated_flow_coordinator.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _routerConfig = FlowRouterConfig(
    home: const AuthenticatedFlowCoordinator(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      darkTheme: ThemeData.dark(),
      routerConfig: _routerConfig,
    );
  }
}
