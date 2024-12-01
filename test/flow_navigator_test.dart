import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_navigator_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'flow_navigator_test.mocks.dart';

@GenerateMocks([
  FlowNavigator,
  BuildContext,
])
void main() {
  group('FlowNavigatorScope', () {
    testWidgets(
      'FlowNavigator.maybeOf retrieves the nearest FlowNavigator',
      (WidgetTester tester) async {
        final rootNavigator = MockFlowNavigator();
        final nestedNavigator = MockFlowNavigator();
        FlowNavigator? retrievedNavigator;

        await tester.pumpWidget(
          MaterialApp(
            home: FlowNavigatorScope(
              navigator: rootNavigator,
              child: FlowNavigatorScope(
                navigator: nestedNavigator,
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        retrievedNavigator = FlowNavigator.maybeOf(context);
                      },
                      child: const Text('Test MaybeOf'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test MaybeOf'));
        expect(retrievedNavigator, equals(nestedNavigator));
      },
    );

    testWidgets(
      'FlowNavigator.maybeOf returns null if no FlowNavigatorScope is found',
      (WidgetTester tester) async {
        FlowNavigator? retrievedNavigator;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    retrievedNavigator = FlowNavigator.maybeOf(context);
                  },
                  child: const Text('Test MaybeOf'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Test MaybeOf'));
        expect(retrievedNavigator, isNull);
      },
    );

    testWidgets(
      'FlowNavigator.of retrieves the nearest FlowNavigator',
      (WidgetTester tester) async {
        final rootNavigator = MockFlowNavigator();
        final nestedNavigator = MockFlowNavigator();
        FlowNavigator? retrievedNavigator;

        await tester.pumpWidget(
          MaterialApp(
            home: FlowNavigatorScope(
              navigator: rootNavigator,
              child: FlowNavigatorScope(
                navigator: nestedNavigator,
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        retrievedNavigator = FlowNavigator.of(context);
                      },
                      child: const Text('Test Of'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Of'));
        expect(retrievedNavigator, equals(nestedNavigator));
      },
    );

    testWidgets(
      'FlowNavigator.of throws an exception if no FlowNavigatorScope is found',
      (WidgetTester tester) async {
        Object? errorObject;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      FlowNavigator.of(context);
                    } catch (e) {
                      errorObject = e;
                    }
                  },
                  child: const Text('Test Of'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Test Of'));
        expect(errorObject, isFlutterError);
      },
    );
  });
}
