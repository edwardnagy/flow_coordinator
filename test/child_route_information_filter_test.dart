import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildRouteInformationFilter', () {
    testWidgets(
      'forwards child route info when parent consumed value matches predicate',
      (tester) async {
        RouteInformation? receivedByChild;
        final router = FlowCoordinatorRouter(
          initialUri: Uri.parse('/books'),
          homeBuilder: (_) => _ParentWithFilteredChild(
            parentChildRoute: RouteInformation(
              uri: Uri.parse('/books/1'),
            ),
            filterPredicate: (info) =>
                info.uri.pathSegments.isNotEmpty &&
                info.uri.pathSegments.first == 'books',
            childBuilder: (context) {
              return _ChildFlowCoordinator(
                onRouteReceived: (info) => receivedByChild = info,
              );
            },
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        expect(receivedByChild, isNotNull);
        expect(receivedByChild!.uri, Uri.parse('/books/1'));
      },
    );

    testWidgets(
      'does not forward child route info when predicate does not match',
      (tester) async {
        RouteInformation? receivedByChild;
        final router = FlowCoordinatorRouter(
          initialUri: Uri.parse('/settings'),
          homeBuilder: (_) => _ParentWithFilteredChild(
            parentChildRoute: RouteInformation(
              uri: Uri.parse('/settings/profile'),
            ),
            filterPredicate: (info) =>
                info.uri.pathSegments.isNotEmpty &&
                info.uri.pathSegments.first == 'books',
            childBuilder: (context) {
              return _ChildFlowCoordinator(
                onRouteReceived: (info) => receivedByChild = info,
              );
            },
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        expect(receivedByChild, isNull);
      },
    );
  });
}

/// A parent flow coordinator that sets consumed and child route info,
/// then nests a ChildRouteInformationFilter with a child flow.
class _ParentWithFilteredChild extends StatefulWidget {
  const _ParentWithFilteredChild({
    required this.parentChildRoute,
    required this.filterPredicate,
    required this.childBuilder,
  });

  final RouteInformation parentChildRoute;
  final RouteInformationPredicate filterPredicate;
  final WidgetBuilder childBuilder;

  @override
  State<_ParentWithFilteredChild> createState() =>
      _ParentWithFilteredChildState();
}

class _ParentWithFilteredChildState extends State<_ParentWithFilteredChild>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        MaterialPage(
          child: FlowRouteScope(
            routeInformation: null,
            shouldForwardChildUpdates: widget.filterPredicate,
            child: widget.childBuilder(context),
          ),
        ),
      ];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(widget.parentChildRoute);
  }
}

/// Child flow coordinator that reports when it receives route info.
class _ChildFlowCoordinator extends StatefulWidget {
  const _ChildFlowCoordinator({required this.onRouteReceived});

  final void Function(RouteInformation) onRouteReceived;

  @override
  State<_ChildFlowCoordinator> createState() => _ChildFlowCoordinatorState();
}

class _ChildFlowCoordinatorState extends State<_ChildFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(child: SizedBox()),
      ];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    widget.onRouteReceived(routeInformation);
    return SynchronousFuture(null);
  }
}
