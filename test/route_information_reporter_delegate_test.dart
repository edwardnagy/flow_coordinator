import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Triggers post-frame callbacks in tests by scheduling a frame
/// and pumping.
Future<void> pumpPostFrameCallbacks(WidgetTester tester) async {
  tester.binding.scheduleFrame();
  await tester.pump();
}

void main() {
  group('RouteInformationReporterDelegate', () {
    testWidgets('of returns delegate when found', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      addTearDown(delegate.dispose);
      late RouteInformationReporterDelegate result;
      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate,
          child: Builder(
            builder: (context) {
              result = RouteInformationReporterDelegate.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, delegate);
    });

    testWidgets('of throws when not found', (tester) async {
      late FlutterError error;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              RouteInformationReporterDelegate.of(context);
            } on FlutterError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      );
      expect(
        error.toString(),
        contains('No RouteInformationReporterScope found.'),
      );
    });
  });

  group('RootRouteInformationReporterDelegate', () {
    test('reportedRouteInformation is initially null', () {
      final delegate = RootRouteInformationReporterDelegate();
      addTearDown(delegate.dispose);
      expect(delegate.reportedRouteInformation, isNull);
    });

    testWidgets(
      'childReportsRouteInformation schedules reporting and '
      'notifies listeners',
      (tester) async {
        final delegate = RootRouteInformationReporterDelegate();
        addTearDown(delegate.dispose);
        var notified = false;
        delegate.addListener(() => notified = true);

        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/test')),
        );

        expect(delegate.reportedRouteInformation, isNull);

        await pumpPostFrameCallbacks(tester);

        expect(notified, isTrue);
        expect(
          delegate.reportedRouteInformation?.uri,
          Uri.parse('/test'),
        );
      },
    );

    testWidgets(
      'childReportsRouteInformation prefixes URI with / '
      'when missing',
      (tester) async {
        final delegate = RootRouteInformationReporterDelegate();
        addTearDown(delegate.dispose);

        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('test')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(
          delegate.reportedRouteInformation?.uri.toString(),
          startsWith('/'),
        );
      },
    );

    testWidgets(
      'childReportsRouteInformation preserves URI already '
      'prefixed with /',
      (tester) async {
        final delegate = RootRouteInformationReporterDelegate();
        addTearDown(delegate.dispose);

        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/existing')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(
          delegate.reportedRouteInformation?.uri,
          Uri.parse('/existing'),
        );
      },
    );

    testWidgets(
      'multiple reports in same frame only reports last value',
      (tester) async {
        final delegate = RootRouteInformationReporterDelegate();
        addTearDown(delegate.dispose);
        var notifyCount = 0;
        delegate.addListener(() => notifyCount++);

        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/first')),
        );
        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/second')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(notifyCount, 1);
        expect(
          delegate.reportedRouteInformation?.uri,
          Uri.parse('/second'),
        );
      },
    );
  });

  group('ChildRouteInformationReporterDelegate', () {
    testWidgets(
      'setCurrentRouteInformation forwards to parent',
      (tester) async {
        final parent = RootRouteInformationReporterDelegate();
        addTearDown(parent.dispose);
        final child = ChildRouteInformationReporterDelegate(
          parent: parent,
          routeInformationCombiner: const DefaultRouteInformationCombiner(),
        );

        child.setCurrentRouteInformation(
          RouteInformation(uri: Uri.parse('/child')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(
          parent.reportedRouteInformation?.uri,
          Uri.parse('/child'),
        );
      },
    );

    testWidgets(
      'childReportsRouteInformation combines with current '
      'and forwards to parent',
      (tester) async {
        final parent = RootRouteInformationReporterDelegate();
        addTearDown(parent.dispose);
        final child = ChildRouteInformationReporterDelegate(
          parent: parent,
          routeInformationCombiner: const DefaultRouteInformationCombiner(),
        );

        child.setCurrentRouteInformation(
          RouteInformation(uri: Uri.parse('/parent')),
        );
        child.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/nested')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(
          parent.reportedRouteInformation?.uri,
          Uri.parse('/parent/nested'),
        );
      },
    );

    testWidgets(
      'childReportsRouteInformation uses empty URI when '
      'current is not set',
      (tester) async {
        final parent = RootRouteInformationReporterDelegate();
        addTearDown(parent.dispose);
        final child = ChildRouteInformationReporterDelegate(
          parent: parent,
          routeInformationCombiner: const DefaultRouteInformationCombiner(),
        );

        child.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/nested')),
        );

        await pumpPostFrameCallbacks(tester);

        expect(
          parent.reportedRouteInformation?.uri,
          Uri.parse('/nested'),
        );
      },
    );
  });

  group('RouteInformationReporterScope', () {
    test('updateShouldNotify returns true when value differs', () {
      final delegate1 = RootRouteInformationReporterDelegate();
      final delegate2 = RootRouteInformationReporterDelegate();
      addTearDown(delegate1.dispose);
      addTearDown(delegate2.dispose);
      final scope = RouteInformationReporterScope(
        delegate1,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          RouteInformationReporterScope(
            delegate2,
            child: const SizedBox(),
          ),
        ),
        isTrue,
      );
    });

    test('updateShouldNotify returns false when value is same', () {
      final delegate = RootRouteInformationReporterDelegate();
      addTearDown(delegate.dispose);
      final scope = RouteInformationReporterScope(
        delegate,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          RouteInformationReporterScope(
            delegate,
            child: const SizedBox(),
          ),
        ),
        isFalse,
      );
    });
  });
}
