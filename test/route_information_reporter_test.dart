import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationReporter', () {
    testWidgets(
      'didUpdateWidget resets reported state when route information changes '
      'but cannot report, allowing reporting when conditions change',
      (tester) async {
        final isActiveNotifier = ValueNotifier(true);
        addTearDown(isActiveNotifier.dispose);

        final routeInfoNotifier = ValueNotifier(
          RouteInformation(uri: Uri.parse('/a')),
        );
        addTearDown(routeInfoNotifier.dispose);

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: ValueListenableBuilder<bool>(
                  valueListenable: isActiveNotifier,
                  builder: (context, isActive, child) {
                    return ValueListenableBuilder<RouteInformation>(
                      valueListenable: routeInfoNotifier,
                      builder: (context, routeInfo, _) {
                        return FlowRouteScope(
                          isActive: isActive,
                          routeInformation: routeInfo,
                          child: const SizedBox(),
                        );
                      },
                    );
                  },
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

        // Route /a should be reported since the route is active and top.
        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/a'),
        );

        // Deactivate the route.
        isActiveNotifier.value = false;
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        // Change route information while inactive.
        routeInfoNotifier.value = RouteInformation(uri: Uri.parse('/b'));
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        // The router should still report the old route information.
        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/a'),
        );

        // Reactivate the route.
        isActiveNotifier.value = true;
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        // The new route information /b is now reported.
        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/b'),
        );
      },
    );

    testWidgets(
      'didUpdateWidget does not report when route information changes '
      'and route is not the top route',
      (tester) async {
        final routeInfoNotifier = ValueNotifier(
          RouteInformation(uri: Uri.parse('/a')),
        );
        addTearDown(routeInfoNotifier.dispose);

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: ValueListenableBuilder<RouteInformation>(
                  valueListenable: routeInfoNotifier,
                  builder: (context, routeInfo, _) {
                    return FlowRouteScope(
                      routeInformation: routeInfo,
                      child: const SizedBox(),
                    );
                  },
                ),
              ),
              const MaterialPage(
                child: FlowRouteScope(
                  child: SizedBox(),
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

        // The non-top route's /a was not reported.
        expect(router.routerDelegate.currentConfiguration?.uri, Uri.parse('/'));

        routeInfoNotifier.value = RouteInformation(uri: Uri.parse('/b'));
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        // The non-top route's /b was not reported.
        expect(router.routerDelegate.currentConfiguration?.uri, Uri.parse('/'));
      },
    );
  });
}

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
}
