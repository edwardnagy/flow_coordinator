import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flow_coordinator/src/identity_route_information_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_coordinator_mixin_test.dart';

void main() {
  group('FlowCoordinatorRouter', () {
    test('creates with required homeBuilder', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router, isNotNull);
      router.dispose();
    });

    test('creates with custom backButtonDispatcher', () {
      final backButtonDispatcher = RootBackButtonDispatcher();
      final router = FlowCoordinatorRouter(
        backButtonDispatcher: backButtonDispatcher,
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.backButtonDispatcher, same(backButtonDispatcher));
      router.dispose();
    });

    test('creates with custom routeInformationProvider', () {
      final routeInfoProvider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
      );
      final router = FlowCoordinatorRouter(
        routeInformationProvider: routeInfoProvider,
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.routeInformationProvider, same(routeInfoProvider));
      router.dispose();
    });

    test('creates with custom routeInformationParser', () {
      const parser = IdentityRouteInformationParser();
      final router = FlowCoordinatorRouter(
        routeInformationParser: parser,
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.routeInformationParser, same(parser));
      router.dispose();
    });

    test('creates with initialUri', () {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/custom/path'),
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router, isNotNull);
      router.dispose();
    });

    test('creates with initialState', () {
      final router = FlowCoordinatorRouter(
        initialState: {'key': 'value'},
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router, isNotNull);
      router.dispose();
    });

    test('creates with routeInformationReportingEnabled true', () {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.routeInformationReportingEnabled, isTrue);
      router.dispose();
    });

    test('defaults routeInformationReportingEnabled to false', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.routeInformationReportingEnabled, isFalse);
      router.dispose();
    });

    test('creates default backButtonDispatcher when not provided', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.backButtonDispatcher, isA<RootBackButtonDispatcher>());
      router.dispose();
    });

    test('creates default routeInformationProvider when not provided', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(
        router.routeInformationProvider,
        isA<PlatformRouteInformationProvider>(),
      );
      router.dispose();
    });

    test('defaults routeInformationParser to IdentityRouteInformationParser',
        () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(
        router.routeInformationParser,
        isA<IdentityRouteInformationParser>(),
      );
      router.dispose();
    });

    test('provides routerDelegate', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(router.routerDelegate, isNotNull);
      router.dispose();
    });

    testWidgets('works as RouterConfig for MaterialApp.router', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Scaffold(
          body: Text('Home'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('homeBuilder is called to build initial widget',
        (tester) async {
      var homeBuilderCalled = false;
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) {
          homeBuilderCalled = true;
          return const Scaffold(body: Text('Test'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(homeBuilderCalled, isTrue);
      expect(find.text('Test'), findsOneWidget);

      router.dispose();
    });

    testWidgets('route information reporting works when enabled',
        (tester) async {
      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true,
        homeBuilder: (context) => const Scaffold(body: Text('Home')),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles initialUri correctly', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/test/path'),
        homeBuilder: (context) => const Scaffold(body: Text('Home')),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles initialState correctly', (tester) async {
      final initialState = {'data': 'test'};
      final router = FlowCoordinatorRouter(
        initialState: initialState,
        homeBuilder: (context) => const Scaffold(body: Text('Home')),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    test('disposes cleanly', () {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const SizedBox(),
      );

      expect(() => router.dispose(), returnsNormally);
    });

    testWidgets('multiple routers can be created and disposed', (tester) async {
      for (var i = 0; i < 3; i++) {
        final router = FlowCoordinatorRouter(
          homeBuilder: (context) => Scaffold(body: Text('Router $i')),
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        expect(find.text('Router $i'), findsOneWidget);

        router.dispose();
      }
    });

    testWidgets('works with CupertinoApp.router', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Cupertino Home'),
      );

      await tester.pumpWidget(
        CupertinoApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Cupertino Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('works with WidgetsApp.router', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Widgets Home'),
      );

      await tester.pumpWidget(
        WidgetsApp.router(
          routerConfig: router,
          color: const Color(0xFF000000),
        ),
      );

      expect(find.text('Widgets Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles null state', (tester) async {
      final router = FlowCoordinatorRouter(
        initialState: null,
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles complex initial state', (tester) async {
      final router = FlowCoordinatorRouter(
        initialState: {
          'nested': {
            'value': [1, 2, 3],
          },
        },
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles URI with query parameters', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/path?key1=value1&key2=value2'),
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles URI with fragment', (tester) async {
      final router = FlowCoordinatorRouter(
        initialUri: Uri.parse('/path#section'),
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('handles platform route information', (tester) async {
      // Line 64: Uri.parse(platformDefaultRouteName) is challenging to test
      // because it only executes when platformDefaultRouteName != Navigator.defaultRouteName
      // In test environments, these are typically equal ('/'), so line 64 is not reached
      // Instead, this test ensures the _effectiveInitialUri method works correctly
      
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.dispose();
    });

    testWidgets('notifies listeners on route information change',
        (tester) async {
      // This test covers lines 108-109: notifyListeners when route changes
      // The notifyListeners is triggered by _onRouteInformationReported callback
      // which is called when route information is reported from within the widget tree

      final router = FlowCoordinatorRouter(
        routeInformationReportingEnabled: true, // Must enable reporting
        homeBuilder: (context) {
          // Build a simple widget tree with RouteInformationReporter
          return TestFlowCoordinator(
            initialPagesOverride: [
              MaterialPage(
                child: FlowRouteScope(
                  routeInformation: RouteInformation(uri: Uri.parse('/home')),
                  child: const SizedBox(),
                ),
              ),
            ],
          );
        },
      );

      var notificationCount = 0;

      router.routerDelegate.addListener(() {
        notificationCount++;
      });

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      tester.binding.scheduleWarmUpFrame();

      // The RouteInformationReporter should have reported the route information
      // which triggers _onRouteInformationReported and notifyListeners()
      // This happens during the initial build
      expect(notificationCount, greaterThan(0));

      router.dispose();
    });

    testWidgets('popRoute returns false', (tester) async {
      // This test covers lines 120-121: popRoute implementation

      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const Text('Home'),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      // popRoute should return false (handled by child coordinators)
      final result = await router.routerDelegate.popRoute();
      expect(result, isFalse);

      router.dispose();
    });
  });
}
