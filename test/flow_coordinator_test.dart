import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinator', () {
    testWidgets('of throws error when no FlowCoordinatorMixin is found',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => FlowCoordinator.of<_TestFlowCoordinatorState>(context),
                throwsA(
                  isA<FlutterError>().having(
                    (e) => e.message,
                    'message',
                    contains(
                      'Could not find a FlowCoordinatorMixin of type '
                      '_TestFlowCoordinatorState',
                    ),
                  ),
                ),
              );
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('of returns the nearest FlowCoordinatorMixin', (tester) async {
      final key = GlobalKey<_TestFlowCoordinatorState>();
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: key,
              child: Builder(
                builder: (context) {
                  final coordinator =
                      FlowCoordinator.of<_TestFlowCoordinatorState>(context);
                  expect(coordinator, isNotNull);
                  expect(coordinator, key.currentState);
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
    });
  });
}

class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Widget build(BuildContext context) {
    // FlowCoordinator.of verification relies on Mixin being present.
    // If we return just widget.child, the mixin is in the tree (as State).
    // BUT we must be careful about didChangeDependencies throwing.
    return widget.child;
  }
}
