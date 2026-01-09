import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpReports(WidgetTester tester) async {
  WidgetsBinding.instance.scheduleFrame();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('RouteInformationReporterDelegate', () {
    testWidgets('of throws when scope not found', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final context = tester.element(find.byType(SizedBox));

      expect(
        () => RouteInformationReporterDelegate.of(context),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('of returns delegate when scope exists', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            delegate,
            child: Builder(
              builder: (context) {
                final found = RouteInformationReporterDelegate.of(context);
                return Text('Found: ${found == delegate}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Found: true'), findsOneWidget);
    });
  });

  group('RootRouteInformationReporterDelegate', () {
    testWidgets('reports route information after post frame callback',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      RouteInformation? reported;

      delegate.addListener(() {
        reported = delegate.reportedRouteInformation;
      });

      // Report should be pending
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('test')),
      );
      expect(reported, isNull);

      // After pump, report should be completed
      await _pumpReports(tester);
      expect(reported, isNotNull);
      expect(reported!.uri.toString(), '/test');
    });

    testWidgets('prefixes URI with slash if missing', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      RouteInformation? reported;

      delegate.addListener(() {
        reported = delegate.reportedRouteInformation;
      });

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('noprefix')),
      );
      await _pumpReports(tester);
      expect(reported?.uri.toString(), '/noprefix');
    });

    testWidgets('keeps slash when already present', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      RouteInformation? reported;

      delegate.addListener(() {
        reported = delegate.reportedRouteInformation;
      });

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/alreadyPrefixed')),
      );
      await _pumpReports(tester);

      expect(reported?.uri.toString(), '/alreadyPrefixed');
    });

    testWidgets('preserves state when reporting', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      RouteInformation? reported;

      delegate.addListener(() {
        reported = delegate.reportedRouteInformation;
      });

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/test'), state: 'custom state'),
      );
      await _pumpReports(tester);

      expect(reported?.state, 'custom state');
    });

    testWidgets('batches multiple reports before frame callback',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      var notifyCount = 0;

      delegate.addListener(() {
        notifyCount++;
      });

      // Multiple reports in same frame
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/first')),
      );
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/second')),
      );
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/third')),
      );

      expect(notifyCount, 0);

      // Should only notify once with the last value
      await _pumpReports(tester);
      expect(notifyCount, 1);
      expect(delegate.reportedRouteInformation?.uri.toString(), '/third');
    });

    testWidgets('handles multiple frames of reports', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final delegate = RootRouteInformationReporterDelegate();
      var notifyCount = 0;

      delegate.addListener(() {
        notifyCount++;
      });

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/first')),
      );
      await _pumpReports(tester);
      expect(notifyCount, 1);

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/second')),
      );
      await _pumpReports(tester);
      expect(notifyCount, 2);
    });
  });

  group('ChildRouteInformationReporterDelegate', () {
    testWidgets('sets current and reports to parent', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final childDelegate = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      childDelegate.setCurrentRouteInformation(
        RouteInformation(uri: Uri.parse('/parent')),
      );

      await _pumpReports(tester);

      expect(parent.reportedRouteInformation?.uri.toString(), '/parent');
    });

    testWidgets('combines child reports with current route', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final childDelegate = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      // Set current route
      childDelegate.setCurrentRouteInformation(
        RouteInformation(uri: Uri.parse('/parent')),
      );
      await _pumpReports(tester);

      // Child reports its own route
      childDelegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/child')),
      );
      await _pumpReports(tester);

      // Should be combined as /parent/child
      expect(
        parent.reportedRouteInformation?.uri.pathSegments,
        ['parent', 'child'],
      );
    });

    testWidgets('uses empty URI when current route not set', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final childDelegate = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      // Child reports without setting current route first
      childDelegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/child')),
      );
      await _pumpReports(tester);

      // Should just be /child
      expect(parent.reportedRouteInformation?.uri.toString(), '/child');
    });

    testWidgets('uses custom combiner when provided', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final parent = RootRouteInformationReporterDelegate();
      final combiner = _TestCombiner();
      final childDelegate = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      childDelegate.setCurrentRouteInformation(
        RouteInformation(uri: Uri.parse('/parent')),
      );
      await tester.pumpAndSettle();

      childDelegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/child')),
      );
      await _pumpReports(tester);

      expect(combiner.combineCalled, true);
      // Ensure the custom combined route is reported by the parent
      expect(parent.reportedRouteInformation?.uri.toString(), '/custom');
      // Validate parameters passed to combiner
      expect(combiner.lastCurrent?.uri.toString(), '/parent');
      expect(combiner.lastChild?.uri.toString(), '/child');
    });
  });

  group('RouteInformationReporterScope', () {
    testWidgets('provides delegate to descendants', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            delegate,
            child: Builder(
              builder: (context) {
                final found = RouteInformationReporterDelegate.of(context);
                return Text('Found: ${found == delegate}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Found: true'), findsOneWidget);
    });

    test('updateShouldNotify returns true when value changes', () {
      final delegate1 = RootRouteInformationReporterDelegate();
      final delegate2 = RootRouteInformationReporterDelegate();
      final scope1 = RouteInformationReporterScope(
        delegate1,
        child: const SizedBox(),
      );
      final scope2 = RouteInformationReporterScope(
        delegate2,
        child: const SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), true);
    });

    test('updateShouldNotify returns false when value same', () {
      final delegate = RootRouteInformationReporterDelegate();
      final scope1 = RouteInformationReporterScope(
        delegate,
        child: const SizedBox(),
      );
      final scope2 = RouteInformationReporterScope(
        delegate,
        child: const SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), false);
    });
  });
}

class _TestCombiner implements RouteInformationCombiner {
  bool combineCalled = false;
  RouteInformation? lastCurrent;
  RouteInformation? lastChild;

  @override
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  }) {
    combineCalled = true;
    lastCurrent = currentRouteInformation;
    lastChild = childRouteInformation;
    return RouteInformation(uri: Uri.parse('/custom'));
  }
}
