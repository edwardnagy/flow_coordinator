import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';

// Integration test that exercises the full flow coordinator stack
class RootFlowCoordinator extends StatefulWidget {
  const RootFlowCoordinator({super.key});

  @override
  State<RootFlowCoordinator> createState() => _RootFlowCoordinatorState();
}

class _RootFlowCoordinatorState extends State<RootFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(
          key: ValueKey('home'),
          child: HomeScreen(),
        ),
      ];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final path = routeInformation.uri.pathSegments.firstOrNull;
    
    if (path == 'details') {
      flowNavigator.push(
        const MaterialPage(
          key: ValueKey('details'),
          child: DetailsScreen(),
        ),
      );
    }
    
    return null;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final coordinator = FlowCoordinator.of<_RootFlowCoordinatorState>(context);
            coordinator.flowNavigator.push(
              const MaterialPage(
                key: ValueKey('details'),
                child: DetailsScreen(),
              ),
            );
          },
          child: const Text('Go to Details'),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            FlowNavigator.of(context).pop();
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}

void main() {
  group('Flow Coordinator Integration Tests', () {
    testWidgets('complete navigation flow works', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const RootFlowCoordinator(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Should show home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Go to Details'), findsOneWidget);

      // Navigate to details
      await tester.tap(find.text('Go to Details'));
      await tester.pumpAndSettle();

      // Should show details screen
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);

      // Navigate back
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      // Should be back at home
      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('deep linking works', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/details'),
        homeBuilder: (context) => const RootFlowCoordinator(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Should navigate to details via deep link
      expect(find.text('Details'), findsOneWidget);

      router.dispose();
    });

    testWidgets('FlowRouteScope reports route information', (tester) async {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => const TestFlowCoordinatorWithRouteScope(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TestFlowCoordinatorWithRouteScope), findsOneWidget);

      router.dispose();
    });

    testWidgets('nested flow coordinators work', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const ParentFlowCoordinator(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChildFlowCoordinator), findsOneWidget);

      router.dispose();
    });

    testWidgets('FlowNavigator.maybeOf returns null without coordinator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final navigator = FlowNavigator.maybeOf(context);
              expect(navigator, isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('pop works with system back button', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const RootFlowCoordinator(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to details
      await tester.tap(find.text('Go to Details'));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);

      // Simulate system back button
      final NavigatorState navigatorState = tester.state(find.byType(Navigator).first);
      await navigatorState.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });
  });
}

// Helper flow coordinators for nested testing
class ParentFlowCoordinator extends StatefulWidget {
  const ParentFlowCoordinator({super.key});

  @override
  State<ParentFlowCoordinator> createState() => _ParentFlowCoordinatorState();
}

class _ParentFlowCoordinatorState extends State<ParentFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(
          key: ValueKey('parent'),
          child: ChildFlowCoordinator(),
        ),
      ];
}

class ChildFlowCoordinator extends StatefulWidget {
  const ChildFlowCoordinator({super.key});

  @override
  State<ChildFlowCoordinator> createState() => _ChildFlowCoordinatorState();
}

class _ChildFlowCoordinatorState extends State<ChildFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(
          key: ValueKey('child'),
          child: Text('Child Flow'),
        ),
      ];
}

// Flow coordinator with route scope for testing
class TestFlowCoordinatorWithRouteScope extends StatefulWidget {
  const TestFlowCoordinatorWithRouteScope({super.key});

  @override
  State<TestFlowCoordinatorWithRouteScope> createState() =>
      _TestFlowCoordinatorWithRouteScopeState();
}

class _TestFlowCoordinatorWithRouteScopeState
    extends State<TestFlowCoordinatorWithRouteScope> with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        MaterialPage(
          key: const ValueKey('home'),
          child: FlowRouteScope(
            routeInformation: RouteInformation(uri: Uri.parse('/')),
            child: const Text('Home with Route Scope'),
          ),
        ),
      ];
}
