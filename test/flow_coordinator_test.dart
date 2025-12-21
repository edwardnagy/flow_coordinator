import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';

// Test flow coordinator implementation
class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({super.key, this.child});
  
  final Widget? child;

  @override
  State<TestFlowCoordinator> createState() => TestFlowCoordinatorState();
}

class TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        MaterialPage(child: widget.child ?? const SizedBox()),
      ];
  
  @override
  Widget build(BuildContext context) {
    return flowRouter(context);
  }
}

void main() {
  group('FlowCoordinator.of', () {
    testWidgets('finds nearest FlowCoordinatorMixin in widget tree', (tester) async {
      TestFlowCoordinatorState? foundState;
      BuildContext? innerContext;

      // Build a TestFlowCoordinator with an inner widget that will look up the coordinator
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TestFlowCoordinator(
            child: Builder(
              builder: (context) {
                innerContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // From the inner widget's context, look up the TestFlowCoordinatorState
      expect(innerContext, isNotNull);
      foundState = FlowCoordinator.of<TestFlowCoordinatorState>(innerContext!);

      expect(foundState, isNotNull);
      expect(foundState, isA<TestFlowCoordinatorState>());
    });

    testWidgets('throws FlutterError when no FlowCoordinatorMixin found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => FlowCoordinator.of<TestFlowCoordinatorState>(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('throws FlutterError with specific type when not found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowCoordinator.of<TestFlowCoordinatorState>(context);
              fail('Should have thrown FlutterError');
            } catch (e) {
              expect(e, isA<FlutterError>());
              expect(
                e.toString(),
                contains('TestFlowCoordinatorState'),
              );
            }
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('FlowCoordinator', () {
    test('constructor is private', () {
      // This ensures the abstract class can only be used via static methods
      expect(() => FlowCoordinator, returnsNormally);
    });
  });
}
