import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpReports(WidgetTester tester) async {
  WidgetsBinding.instance.scheduleFrame();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('RouteInformationReporter', () {
    testWidgets('reports when active and top route', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: true,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: RouteInformationReporterScope(
                parent,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/reported'),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      await _pumpReports(tester);
      expect(parent.reportedRouteInformation?.uri.toString(), '/reported');
    });

    testWidgets('didUpdateWidget reports on change when active',
        (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      var info = RouteInformation(uri: Uri.parse('/one'));

      Widget buildTree() => MaterialApp(
            home: FlowRouteStatusScope(
              isActive: true,
              isTopRoute: true,
              child: RouteInformationCombinerScope(
                const DefaultRouteInformationCombiner(),
                child: RouteInformationReporterScope(
                  parent,
                  child: RouteInformationReporter(
                    routeInformation: info,
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );

      await tester.pumpWidget(buildTree());
      await _pumpReports(tester);
      expect(parent.reportedRouteInformation?.uri.toString(), '/one');

      info = RouteInformation(uri: Uri.parse('/two'));
      await tester.pumpWidget(buildTree());
      await _pumpReports(tester);
      expect(parent.reportedRouteInformation?.uri.toString(), '/two');
    });

    testWidgets('does not report when not active', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteStatusScope(
            isActive: false,
            isTopRoute: true,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: RouteInformationReporterScope(
                parent,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/blocked'),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      await _pumpReports(tester);
      expect(parent.reportedRouteInformation, isNull);
    });

    testWidgets('does not report when not top route', (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: false,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: RouteInformationReporterScope(
                parent,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/not-top'),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      await _pumpReports(tester);
      expect(parent.reportedRouteInformation, isNull);
    });

    testWidgets('resets reported state when update cannot be reported',
        (tester) async {
      final parent = RootRouteInformationReporterDelegate();
      final statusNotifier = ValueNotifier(true);
      var info = RouteInformation(uri: Uri.parse('/one'));

      Widget buildTree() => MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: statusNotifier,
              builder: (context, isTopRoute, _) {
                return FlowRouteStatusScope(
                  isActive: true,
                  isTopRoute: isTopRoute,
                  child: RouteInformationCombinerScope(
                    const DefaultRouteInformationCombiner(),
                    child: RouteInformationReporterScope(
                      parent,
                      child: RouteInformationReporter(
                        routeInformation: info,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
          );

      // Start with canReport=true
      await tester.pumpWidget(buildTree());
      await _pumpReports(tester);
      expect(parent.reportedRouteInformation?.uri.toString(), '/one');

      // Change routeInformation AND make canReport=false
      info = RouteInformation(uri: Uri.parse('/two'));
      statusNotifier.value = false;
      await tester.pumpWidget(buildTree());
      await _pumpReports(tester);

      // Should not have reported /two since canReport became false
      expect(parent.reportedRouteInformation?.uri.toString(), '/one');
    });

    // Note: didUpdateWidget branch is exercised indirectly in
    // integration tests.
  });
}
