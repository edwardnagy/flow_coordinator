import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';

void main() {
  group('RouteInformationReporterDelegate.of', () {
    testWidgets('finds delegate in widget tree', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      RouteInformationReporterDelegate? found;

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate,
          child: Builder(
            builder: (context) {
              found = RouteInformationReporterDelegate.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(delegate));
      delegate.dispose();
    });

    testWidgets('throws FlutterError when no scope found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => RouteInformationReporterDelegate.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('RootRouteInformationReporterDelegate', () {
    test('initially has no reported route information', () {
      final delegate = RootRouteInformationReporterDelegate();
      expect(delegate.reportedRouteInformation, isNull);
      delegate.dispose();
    });

    testWidgets('childReportsRouteInformation schedules reporting', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      expect(notified, isFalse); // Not notified yet

      await tester.pump(); // Process post-frame callback

      expect(notified, isTrue);
      expect(delegate.reportedRouteInformation, isNotNull);
      expect(delegate.reportedRouteInformation!.uri.path, equals('/test'));

      delegate.dispose();
    });

    testWidgets('prefixes URI with slash if missing', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('test')),
      );

      await tester.pump();

      expect(delegate.reportedRouteInformation!.uri.toString(), equals('/test'));

      delegate.dispose();
    });

    testWidgets('does not prefix URI if already has slash', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      await tester.pump();

      expect(delegate.reportedRouteInformation!.uri.toString(), equals('/test'));

      delegate.dispose();
    });

    testWidgets('preserves state when reporting', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      final state = {'key': 'value'};

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/test'), state: state),
      );

      await tester.pump();

      expect(delegate.reportedRouteInformation!.state, same(state));

      delegate.dispose();
    });

    testWidgets('multiple reports use last value', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/first')),
      );
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/second')),
      );
      delegate.childReportsRouteInformation(
        RouteInformation(uri: Uri.parse('/third')),
      );

      await tester.pump();

      expect(delegate.reportedRouteInformation!.uri.path, equals('/third'));

      delegate.dispose();
    });
  });

  group('ChildRouteInformationReporterDelegate', () {
    test('creates with parent and combiner', () {
      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final child = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      expect(child, isNotNull);

      parent.dispose();
    });

    testWidgets('setCurrentRouteInformation reports to parent', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final child = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      child.setCurrentRouteInformation(
        RouteInformation(uri: Uri.parse('/child')),
      );

      await tester.pump();

      expect(parent.reportedRouteInformation, isNotNull);
      expect(parent.reportedRouteInformation!.uri.path, equals('/child'));

      parent.dispose();
    });

    testWidgets('childReportsRouteInformation combines with current', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final child = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      child.setCurrentRouteInformation(
        RouteInformation(uri: Uri(pathSegments: ['parent'])),
      );

      await tester.pump();

      child.childReportsRouteInformation(
        RouteInformation(uri: Uri(pathSegments: ['child'])),
      );

      await tester.pump();

      expect(parent.reportedRouteInformation!.uri.pathSegments, equals(['parent', 'child']));

      parent.dispose();
    });

    testWidgets('uses empty URI when no current route set', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      const combiner = DefaultRouteInformationCombiner();
      final child = ChildRouteInformationReporterDelegate(
        parent: parent,
        routeInformationCombiner: combiner,
      );

      child.childReportsRouteInformation(
        RouteInformation(uri: Uri(pathSegments: ['child'])),
      );

      await tester.pump();

      expect(parent.reportedRouteInformation!.uri.pathSegments, equals(['child']));

      parent.dispose();
    });
  });

  group('RouteInformationReporterScope', () {
    testWidgets('provides value to descendants', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate,
          child: Builder(
            builder: (context) {
              final found = RouteInformationReporterDelegate.of(context);
              expect(found, same(delegate));
              return const SizedBox();
            },
          ),
        ),
      );

      delegate.dispose();
    });

    testWidgets('updateShouldNotify returns true when value changes', (tester) async {
      final delegate1 = RootRouteInformationReporterDelegate();
      final delegate2 = RootRouteInformationReporterDelegate();
      var rebuildCount = 0;

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate1,
          child: Builder(
            builder: (context) {
              RouteInformationReporterDelegate.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate2,
          child: Builder(
            builder: (context) {
              RouteInformationReporterDelegate.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 2);

      delegate1.dispose();
      delegate2.dispose();
    });

    testWidgets('updateShouldNotify returns false when same value', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      var rebuildCount = 0;

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate,
          child: Builder(
            builder: (context) {
              RouteInformationReporterDelegate.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        RouteInformationReporterScope(
          delegate,
          child: Builder(
            builder: (context) {
              RouteInformationReporterDelegate.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      delegate.dispose();
    });
  });
}
