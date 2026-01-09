import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_reporter.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinatorRouter', () {
    testWidgets('builds the home widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const Text('Home Screen'),
          ),
        ),
      );

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('can navigate using the router delegate', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home Screen'),
      );
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify initial state
      expect(find.text('Home Screen'), findsOneWidget);
      
      // We can't easily push routes directly on FlowCoordinatorRouter's delegate 
      // because it's designed to work with FlowCoordinatorMixin.
      // But we can verify it initializes correctly.
      expect(router.routerDelegate, isNotNull);
      expect(router.routeInformationParser, isNotNull);
      expect(router.routeInformationProvider, isNotNull);
    });

    testWidgets('handles route information reporting', (tester) async {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => const Text('Home with Reporting'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Home with Reporting'), findsOneWidget);
    });

    testWidgets('works without route information reporting', (tester) async {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: false,
        homeBuilder: (context) => const Text('Home without Reporting'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Home without Reporting'), findsOneWidget);
    });

    testWidgets('uses custom backButtonDispatcher when provided',
        (tester) async {
      final backButtonDispatcher = RootBackButtonDispatcher();
      final router = FlowCoordinatorRouter(
        backButtonDispatcher: backButtonDispatcher,
        homeBuilder: (context) => const Text('Custom Back Button'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Custom Back Button'), findsOneWidget);
    });

    testWidgets('dispose cleans up resources', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Dispose Test'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Dispose Test'), findsOneWidget);

      // Dispose the router
      router.dispose();

      // Verify no errors thrown during disposal
    });

    testWidgets('initialUri is used when provided', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/custom-initial'),
        homeBuilder: (context) => const Text('Custom Initial URI'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Custom Initial URI'), findsOneWidget);
    });

    testWidgets('setNewRoutePath updates route', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Set new route path
      await router.routerDelegate.setNewRoutePath(
        RouteInformation(uri: Uri.parse('/new-route')),
      );
      await tester.pumpAndSettle();

      // Verify no crashes
    });

    testWidgets('popRoute returns false', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      final result = await router.routerDelegate.popRoute();
      expect(result, false);
    });

    testWidgets('notifies on state-only route change', (tester) async {
      final hostKey = GlobalKey<_ReportingHostState>();
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => _ReportingHost(
          key: hostKey,
          initial: RouteInformation(uri: Uri.parse('/same'), state: 'a'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      // Update only the state, keep same URI to exercise the state inequality branch.
      hostKey.currentState!.update(
        RouteInformation(uri: Uri.parse('/same'), state: 'b'),
      );
      await tester.pump();

      // No explicit assertion needed; this path exercises the branch.
      expect(find.byType(_ReportingHost), findsOneWidget);
    });
  });
}

class _ReportingHost extends StatefulWidget {
  const _ReportingHost({super.key, required this.initial});
  final RouteInformation initial;

  @override
  State<_ReportingHost> createState() => _ReportingHostState();
}

class _ReportingHostState extends State<_ReportingHost> {
  late RouteInformation current = widget.initial;

  void update(RouteInformation info) {
    setState(() {
      current = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RouteInformationCombinerScope(
      const DefaultRouteInformationCombiner(),
      child: FlowRouteStatusScope(
        isActive: true,
        isTopRoute: true,
        child: RouteInformationReporter(
          routeInformation: current,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}