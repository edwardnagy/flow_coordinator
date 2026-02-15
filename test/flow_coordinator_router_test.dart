import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinatorRouter', () {
    group('effectiveInitialUri', () {
      test(
        'uses platform route when it differs from default',
        () {
          final result = FlowCoordinatorRouter.effectiveInitialUri(
            initialUri: Uri.parse('/initial'),
            platformDefaultRouteNameOverride: '/platform',
          );
          expect(result, Uri.parse('/platform'));
        },
      );

      test(
        'uses initialUri when platform route is the default',
        () {
          final result = FlowCoordinatorRouter.effectiveInitialUri(
            initialUri: Uri.parse('/initial'),
            platformDefaultRouteNameOverride: Navigator.defaultRouteName,
          );
          expect(result, Uri.parse('/initial'));
        },
      );

      test(
        'falls back to defaultRouteName when both are null/default',
        () {
          final result = FlowCoordinatorRouter.effectiveInitialUri(
            initialUri: null,
            platformDefaultRouteNameOverride: Navigator.defaultRouteName,
          );
          expect(
            result,
            Uri.parse(Navigator.defaultRouteName),
          );
        },
      );
    });

    testWidgets('creates router with default configuration', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (_) => const SizedBox(),
      );
      addTearDown(router.dispose);

      expect(router.routeInformationParser, isNotNull);
      expect(router.routeInformationReportingEnabled, isTrue);
    });

    testWidgets(
      'builds correct widget tree with home widget',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => const Text('Home'),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets(
      'dispose does not throw',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => const SizedBox(),
        );

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        // Pump a different widget to remove the router from tree
        await tester.pumpWidget(const SizedBox());

        router.dispose();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'routeInformationReportingEnabled can be set to false',
      (tester) async {
        final router = FlowCoordinatorRouter(
          routeInformationReportingEnabled: false,
          homeBuilder: (_) => const SizedBox(),
        );
        addTearDown(router.dispose);

        expect(router.routeInformationReportingEnabled, isFalse);
      },
    );

    testWidgets(
      'accepts custom backButtonDispatcher',
      (tester) async {
        final dispatcher = RootBackButtonDispatcher();
        final router = FlowCoordinatorRouter(
          backButtonDispatcher: dispatcher,
          homeBuilder: (_) => const SizedBox(),
        );
        addTearDown(router.dispose);

        expect(router.backButtonDispatcher, dispatcher);
      },
    );

    testWidgets(
      'accepts initialUri',
      (tester) async {
        final router = FlowCoordinatorRouter(
          initialUri: Uri.parse('/custom'),
          homeBuilder: (_) => const SizedBox(),
        );
        addTearDown(router.dispose);

        expect(
          router.routeInformationProvider.value.uri,
          Uri.parse('/custom'),
        );
      },
    );

    testWidgets(
      'accepts initialState',
      (tester) async {
        final router = FlowCoordinatorRouter(
          initialState: 'myState',
          homeBuilder: (_) => const SizedBox(),
        );
        addTearDown(router.dispose);

        expect(
          router.routeInformationProvider.value.state,
          'myState',
        );
      },
    );

    testWidgets(
      'popRoute returns false',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => const SizedBox(),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        final result = await router.routerDelegate.popRoute();
        expect(result, isFalse);
      },
    );

    testWidgets(
      'detects route info change when URI is same but state differs',
      (tester) async {
        final stateNotifier = ValueNotifier<Object?>('stateA');

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: ValueListenableBuilder<Object?>(
                  valueListenable: stateNotifier,
                  builder: (_, state, __) => FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/same-uri'),
                      state: state,
                    ),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        );
        addTearDown(router.dispose);
        addTearDown(stateNotifier.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );
        tester.binding.scheduleWarmUpFrame();

        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/same-uri'),
        );
        expect(
          router.routerDelegate.currentConfiguration?.state,
          'stateA',
        );

        // Change state without changing URI to exercise the state
        // comparison branch.
        stateNotifier.value = 'stateB';
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/same-uri'),
        );
        expect(
          router.routerDelegate.currentConfiguration?.state,
          'stateB',
        );
      },
    );

    testWidgets(
      'does not report route info when reporting is disabled',
      (tester) async {
        final router = FlowCoordinatorRouter(
          routeInformationReportingEnabled: false,
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: FlowRouteScope(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/test'),
                  ),
                  child: const SizedBox(),
                ),
              ),
            ],
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );
        tester.binding.scheduleWarmUpFrame();

        expect(
          router.routerDelegate.currentConfiguration?.uri,
          isNot(Uri.parse('/test')),
        );
      },
    );
  });
}

/// Minimal flow coordinator for route info reporting tests.
class _TestFlowCoordinator extends StatefulWidget {
  const _TestFlowCoordinator({required this.pages});

  final List<Page> pages;

  @override
  State<_TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<_TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => widget.pages;

  @override
  Widget build(BuildContext context) => flowRouter(context);
}
