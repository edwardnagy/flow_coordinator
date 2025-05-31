import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import 'flows/home_flow_coordinator.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = FlowCoordinatorRouter(
    routeInformationReportingEnabled: true,
    homeBuilder: (context) => const HomeFlowCoordinator(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      darkTheme: ThemeData.dark(),
      routerConfig: _router,
    );
  }
}
