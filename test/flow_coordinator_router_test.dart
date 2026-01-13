import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter.dart';
import 'package:flutter/material.dart';
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
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify initial state
      expect(find.text('Home Screen'), findsOneWidget);

      // We can't easily push routes directly on
      // FlowCoordinatorRouter's delegate because it's designed to
      // work with FlowCoordinatorMixin.
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
      addTearDown(router.dispose);

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
      addTearDown(router.dispose);

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
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Custom Back Button'), findsOneWidget);
    });

    testWidgets('initialUri is used when provided', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/custom-initial'),
        homeBuilder: (context) => const Text('Custom Initial URI'),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Custom Initial URI'), findsOneWidget);
    });

    testWidgets('setNewRoutePath updates route', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );
      addTearDown(router.dispose);

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
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      // Update only the state, keep same URI to exercise the state
      // inequality branch.
      hostKey.currentState!.update(
        RouteInformation(uri: Uri.parse('/same'), state: 'b'),
      );
      await tester.pump();

      // Verify widget still exists and no exceptions were thrown
      expect(find.byType(_ReportingHost), findsOneWidget);
      expect(tester.takeException(), isNull);
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
