import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/flow_coordinator.dart';

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

    test('defaults routeInformationParser to IdentityRouteInformationParser', () {
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

    testWidgets('homeBuilder is called to build initial widget', (tester) async {
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

    testWidgets('route information reporting works when enabled', (tester) async {
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
  });
}
