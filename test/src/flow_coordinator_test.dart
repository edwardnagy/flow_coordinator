import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestFlowCoordinator extends StatefulWidget {
  const _TestFlowCoordinator({required this.child});

  final Widget child;

  @override
  State<_TestFlowCoordinator> createState() => TestFlowCoordinatorState();
}

class TestFlowCoordinatorState extends State<_TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        MaterialPage(child: widget.child),
      ];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) =>
      SynchronousFuture(null);
}

void main() {
  group('FlowCoordinator', () {
    testWidgets(
      'of returns the nearest FlowCoordinatorMixin ancestor',
      (tester) async {
        late TestFlowCoordinatorState result;
        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: FlowCoordinatorRouter(
              homeBuilder: (_) => _TestFlowCoordinator(
                child: Builder(
                  builder: (context) {
                    result =
                        FlowCoordinator.of<TestFlowCoordinatorState>(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
            color: const Color(0xFF000000),
          ),
        );

        expect(result.flowNavigator, isA<FlowNavigator>());
      },
    );

    testWidgets('of throws when no ancestor is found', (tester) async {
      late FlutterError error;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowCoordinator.of<TestFlowCoordinatorState>(
                context,
              );
            } on FlutterError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      );

      expect(
        error.toString(),
        contains('TestFlowCoordinatorState'),
      );
    });
  });
}
