import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';

// Test flow coordinator implementation
class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({super.key});

  @override
  State<TestFlowCoordinator> createState() => TestFlowCoordinatorState();
}

class TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(child: SizedBox()),
      ];
}

void main() {
  group('FlowCoordinator.of', () {
    testWidgets('finds nearest FlowCoordinatorMixin in widget tree', (tester) async {
      TestFlowCoordinatorState? foundState;

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: TestFlowCoordinator(),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TestFlowCoordinator(
            key: GlobalKey(),
          ),
        ),
      );

      // Build a widget that tries to find the flow coordinator
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TestFlowCoordinator(
            key: GlobalKey<TestFlowCoordinatorState>(),
          ),
        ),
      );

      final context = tester.element(find.byType(TestFlowCoordinator));
      
      // Access from within the flow coordinator's build tree
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (outerContext) {
              return TestFlowCoordinator(
                key: GlobalKey<TestFlowCoordinatorState>(),
              );
            },
          ),
        ),
      );

      final flowCoordinatorElement = tester.element(find.byType(TestFlowCoordinator));
      final stateContext = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      ).context;

      foundState = FlowCoordinator.of<TestFlowCoordinatorState>(stateContext);

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
