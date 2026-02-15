import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationReporter', () {
    testWidgets(
      'reports route info when active and top route',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: FlowRouteScope(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/reported'),
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
          Uri.parse('/reported'),
        );
      },
    );

    testWidgets(
      'does not report when isActive is false',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            pages: [
              MaterialPage(
                child: FlowRouteScope(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/inactive'),
                  ),
                  isActive: false,
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
          isNot(Uri.parse('/inactive')),
        );
      },
    );

    testWidgets(
      'updates reported route info when route information changes',
      (tester) async {
        final routeInfoNotifier = ValueNotifier(
          RouteInformation(uri: Uri.parse('/page-a')),
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
          Uri.parse('/page-a'),
        );

        routeInfoNotifier.value = RouteInformation(
          uri: Uri.parse('/page-b'),
        );
        await tester.pump();
        tester.binding.scheduleWarmUpFrame();

        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/page-b'),
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
