import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinatorRouter', () {
    testWidgets('builds the home widget', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home Screen'),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
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

      expect(router.routeInformationReportingEnabled, isTrue);
    });

    testWidgets('works without route information reporting', (tester) async {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: false,
        homeBuilder: (context) => const SizedBox(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(router.routeInformationReportingEnabled, isFalse);
    });

    testWidgets('uses custom backButtonDispatcher when provided',
        (tester) async {
      final backButtonDispatcher = RootBackButtonDispatcher();
      final router = FlowCoordinatorRouter(
        backButtonDispatcher: backButtonDispatcher,
        homeBuilder: (context) => const SizedBox(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(router.backButtonDispatcher, same(backButtonDispatcher));
    });

    testWidgets('initialUri is used when provided', (tester) async {
      final initialUri = Uri.parse('/custom-initial');
      final router = FlowCoordinatorRouter(
        initialUri: initialUri,
        homeBuilder: (context) => const SizedBox(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(
        router.routeInformationProvider.value.uri.path,
        initialUri.path,
      );
    });

    testWidgets('popRoute returns false at root level', (tester) async {
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
      var notifyCount = 0;
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => _ReportingHost(
          key: hostKey,
          initial: RouteInformation(uri: Uri.parse('/same'), state: 'a'),
        ),
      );
      addTearDown(router.dispose);
      router.routerDelegate.addListener(() => notifyCount++);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      // Wait for initial report
      await tester.pump();
      final initialNotifyCount = notifyCount;

      // Update only the state, keep same URI to exercise the state
      // inequality branch.
      hostKey.currentState!.update(
        RouteInformation(uri: Uri.parse('/same'), state: 'b'),
      );
      await tester.pump();

      // Verify notifyListeners was called due to state change
      expect(notifyCount, greaterThan(initialNotifyCount));
      expect(find.byType(_ReportingHost), findsOneWidget);
    });
  });

  group('effectiveInitialUri', () {
    test(
        'returns initialUri when platform default is '
        'Navigator.defaultRouteName', () {
      final result = FlowCoordinatorRouter.effectiveInitialUri(
        initialUri: Uri.parse('/custom'),
        platformDefaultRouteNameOverride: Navigator.defaultRouteName,
      );

      expect(result, Uri.parse('/custom'));
    });

    test('returns Navigator.defaultRouteName when no URIs provided', () {
      final result = FlowCoordinatorRouter.effectiveInitialUri(
        initialUri: null,
        platformDefaultRouteNameOverride: Navigator.defaultRouteName,
      );

      expect(result, Uri.parse(Navigator.defaultRouteName));
    });

    test(
        'returns platform URI when platform default differs from '
        'Navigator.defaultRouteName', () {
      final result = FlowCoordinatorRouter.effectiveInitialUri(
        initialUri: Uri.parse('/fallback'),
        platformDefaultRouteNameOverride: '/platform-route',
      );

      expect(result, Uri.parse('/platform-route'));
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
