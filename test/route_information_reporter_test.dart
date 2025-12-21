import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationReporter', () {
    testWidgets('builds with required parameters', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/test')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RouteInformationReporter), findsOneWidget);

      delegate.dispose();
    });

    testWidgets('reports route information when active and top route',
        (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: routeInfo,
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation, isNotNull);
      expect(delegate.reportedRouteInformation!.uri.path, equals('/test'));

      delegate.dispose();
    });

    testWidgets('does not report when route is not active', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: false,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/test')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation, isNull);

      delegate.dispose();
    });

    testWidgets('does not report when route is not top route', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: false,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/test')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation, isNull);

      delegate.dispose();
    });

    testWidgets('does not report when routeInformation is null',
        (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: const RouteInformationCombinerScope(
              DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: null,
                  child: SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation, isNull);

      delegate.dispose();
    });

    testWidgets('reports when routeInformation changes', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/first')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation!.uri.path, equals('/first'));

      // Update route information
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/second')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation!.uri.path, equals('/second'));

      delegate.dispose();
    });

    testWidgets('stops reporting when route becomes inactive', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/test')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation, isNotNull);

      final firstReported = delegate.reportedRouteInformation;

      // Make route inactive
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: false,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation:
                      RouteInformation(uri: Uri.parse('/changed')),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      // Should not have updated because route is inactive
      expect(delegate.reportedRouteInformation, same(firstReported));

      delegate.dispose();
    });

    testWidgets('works without FlowRouteStatusScope (defaults to active)',
        (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: RouteInformationReporter(
                routeInformation: RouteInformation(uri: Uri.parse('/test')),
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      // Without FlowRouteStatusScope, isTopRoute defaults to false,
      // so it should not report
      expect(delegate.reportedRouteInformation, isNull);

      delegate.dispose();
    });

    testWidgets('creates child delegate with parent and combiner',
        (tester) async {
      final delegate = RootRouteInformationReporterDelegate();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(uri: Uri.parse('/parent')),
                  child: RouteInformationReporter(
                    routeInformation:
                        RouteInformation(uri: Uri.parse('/child')),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      // Inner reporter should combine routes
      expect(delegate.reportedRouteInformation, isNotNull);

      delegate.dispose();
    });

    testWidgets('preserves route information state', (tester) async {
      final delegate = RootRouteInformationReporterDelegate();
      final state = {'key': 'value'};

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteInformationReporterScope(
            delegate,
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: true,
                child: RouteInformationReporter(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/test'),
                    state: state,
                  ),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.scheduleWarmUpFrame();

      expect(delegate.reportedRouteInformation!.state, equals(state));

      delegate.dispose();
    });
  });
}
