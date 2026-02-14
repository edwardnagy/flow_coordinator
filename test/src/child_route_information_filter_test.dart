import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal flow coordinator with route info callback support.
class _TestFlowCoordinator extends StatefulWidget {
  const _TestFlowCoordinator({
    required this.pages,
    this.onNewRouteInformationCallback,
  });

  final List<Page> pages;
  final Future<RouteInformation?> Function(RouteInformation)?
      onNewRouteInformationCallback;

  @override
  State<_TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<_TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => widget.pages;

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    if (widget.onNewRouteInformationCallback != null) {
      return widget.onNewRouteInformationCallback!(routeInformation);
    }
    return super.onNewRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) => flowRouter(context);
}

Widget _buildTestApp({
  required WidgetBuilder homeBuilder,
  Uri? initialUri,
}) {
  return WidgetsApp.router(
    routerConfig: FlowCoordinatorRouter(
      homeBuilder: homeBuilder,
      initialUri: initialUri,
    ),
    color: const Color(0xFF000000),
  );
}

void main() {
  group('ChildRouteInformationFilter', () {
    testWidgets(
      'forwards route info when shouldForwardChildUpdates '
      'returns true',
      (tester) async {
        RouteInformation? receivedRouteInfo;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              pages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/parent'),
                    ),
                    shouldForwardChildUpdates: (_) => true,
                    child: _TestFlowCoordinator(
                      pages: const [
                        MaterialPage(child: SizedBox()),
                      ],
                      onNewRouteInformationCallback: (info) {
                        receivedRouteInfo = info;
                        return SynchronousFuture(null);
                      },
                    ),
                  ),
                ),
              ],
              onNewRouteInformationCallback: (info) {
                return SynchronousFuture(
                  RouteInformation(uri: Uri.parse('/child')),
                );
              },
            ),
            initialUri: Uri.parse('/parent/child'),
          ),
        );

        expect(receivedRouteInfo, isNotNull);
        expect(receivedRouteInfo!.uri, Uri.parse('/child'));
      },
    );

    testWidgets(
      'blocks route info when shouldForwardChildUpdates '
      'returns false',
      (tester) async {
        RouteInformation? receivedRouteInfo;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              pages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/parent'),
                    ),
                    shouldForwardChildUpdates: (_) => false,
                    child: _TestFlowCoordinator(
                      pages: const [
                        MaterialPage(child: SizedBox()),
                      ],
                      onNewRouteInformationCallback: (info) {
                        receivedRouteInfo = info;
                        return SynchronousFuture(null);
                      },
                    ),
                  ),
                ),
              ],
              onNewRouteInformationCallback: (info) {
                return SynchronousFuture(
                  RouteInformation(uri: Uri.parse('/child')),
                );
              },
            ),
            initialUri: Uri.parse('/parent/child'),
          ),
        );

        expect(receivedRouteInfo, isNull);
      },
    );
  });
}
