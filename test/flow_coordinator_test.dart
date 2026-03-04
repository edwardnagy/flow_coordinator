import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinator', () {
    testWidgets(
      'of throws FlutterError when no matching ancestor exists',
      (tester) async {
        FlutterError? caughtError;

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              try {
                FlowCoordinator.of(context);
              } on FlutterError catch (e) {
                caughtError = e;
              }
              return const SizedBox();
            },
          ),
        );

        expect(caughtError, isNotNull);
        expect(
          caughtError!.message,
          contains('Could not find a FlowCoordinatorMixin of type'),
        );
      },
    );
  });
}
