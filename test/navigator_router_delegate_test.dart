import 'package:flow_coordinator/src/navigator_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigatorRouterDelegate', () {
    testWidgets(
      'initializes with the initial pages',
      (tester) async {
        final delegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
          ),
        );

        expect(find.text('Home Page'), findsNothing);
        expect(find.text('Details Page'), findsOneWidget);

        delegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
      },
    );

    testWidgets(
      'push adds a new page to the navigation stack',
      (tester) async {
        final delegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
          ),
        );

        expect(find.text('Home Page'), findsOneWidget);

        // Push a new page
        delegate.push(const MaterialPage(child: Text('Details Page')));
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsNothing);
        expect(find.text('Details Page'), findsOneWidget);

        // Pop the page
        delegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
      },
    );

    testWidgets(
      'replaceCurrentPage replaces the top page',
      (tester) async {
        final delegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Old Details Page')),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
          ),
        );

        expect(find.text('Old Details Page'), findsOneWidget);

        // Replace the current page
        delegate.replaceCurrentPage(
            const MaterialPage(child: Text('New Details Page')));
        await tester.pumpAndSettle();

        // The old page should be replaced
        expect(find.text('Old Details Page'), findsNothing);
        expect(find.text('New Details Page'), findsOneWidget);

        // Pop the page
        delegate.pop();
        await tester.pumpAndSettle();

        // The pages below the replaced page should be intact
        expect(find.text('Home Page'), findsOneWidget);
      },
    );

    testWidgets(
      'setPages updates the navigation stack',
      (tester) async {
        final delegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Old Page')),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
          ),
        );

        expect(find.text('Old Page'), findsOneWidget);

        // Set new pages
        delegate.setPages([
          const MaterialPage(child: Text('New Page 1')),
          const MaterialPage(child: Text('New Page 2')),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Old Page'), findsNothing);
        expect(find.text('New Page 1'), findsNothing);
        expect(find.text('New Page 2'), findsOneWidget);

        // Pop the page
        delegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('New Page 1'), findsOneWidget);
      },
    );

    testWidgets(
      'canPopInternally returns true '
      'if there are at least two pages to pop internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(testDelegate.canPopInternally(), isTrue);
      },
    );

    testWidgets(
      'canPopInternally returns false '
      'if there is only one page to pop internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(testDelegate.canPopInternally(), isFalse);
      },
    );

    testWidgets(
      'maybePopInternally pops the top page internally and returns true '
      'if there are at least two pages to pop internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Details Page'), findsOneWidget);

        // Pop the page
        final result = await testDelegate.maybePopInternally();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
        expect(find.text('Details Page'), findsNothing);
        expect(result, isTrue);
      },
    );

    testWidgets(
      'maybePopInternally does nothing and returns false '
      'if there is only one page to pop internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Home Page'), findsOneWidget);

        // Pop the page
        final result = await testDelegate.maybePopInternally();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
        expect(result, isFalse);
      },
    );

    testWidgets(
      'popInternally pops the top page internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Details Page'), findsOneWidget);

        // Pop the page
        testDelegate.popInternally();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
        expect(find.text('Details Page'), findsNothing);

        // Pop the page
        testDelegate.popInternally();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsNothing);
        expect(find.text('Details Page'), findsNothing);
      },
    );

    testWidgets(
      'canPop returns true if there are pages to pop internally',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(testDelegate.canPop(), isTrue);
      },
    );

    testWidgets(
      'canPop returns true if there are pages to pop in the parent navigator',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(testDelegate.canPop(), isTrue);
      },
    );

    testWidgets(
      'canPop returns false if there are no pages to pop internally '
      'and in the parent navigator',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(testDelegate.canPop(), isFalse);
      },
    );

    testWidgets(
      'maybePop pops the top page in the parent navigator and returns true '
      'if there are no pages to pop internally, but in the parent navigator',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Home Page'), findsOneWidget);

        // Pop the page
        final result = await testDelegate.maybePop();
        await tester.pumpAndSettle();

        expect(find.text('Root Page'), findsOneWidget);
        expect(find.text('Home Page'), findsNothing);
        expect(result, isTrue);
      },
    );

    testWidgets(
      'maybePop does nothing and returns false '
      'if there are no pages to pop internally and in the parent navigator',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Home Page'), findsOneWidget);

        // Pop the page
        final result = await testDelegate.maybePop();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
        expect(result, isFalse);
      },
    );

    testWidgets(
      'pop pops the top page both internally and in the parent navigator',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
            const MaterialPage(child: Text('Details Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Root Page')),
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Details Page'), findsOneWidget);

        testDelegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('Root Page'), findsNothing);
        expect(find.text('Home Page'), findsOneWidget);
        expect(find.text('Details Page'), findsNothing);

        testDelegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('Root Page'), findsOneWidget);
        expect(find.text('Home Page'), findsNothing);
        expect(find.text('Details Page'), findsNothing);
      },
    );

    testWidgets(
      'pop pops the last page in the parent navigator '
      'if there are no remaining pages',
      (tester) async {
        final testDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            const MaterialPage(child: Text('Home Page')),
          ],
        );
        final parentDelegate = NavigatorRouterDelegate<Object>(
          initialPages: [
            MaterialPage(
              child: Router(
                routerDelegate: testDelegate,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: parentDelegate,
          ),
        );

        expect(find.text('Home Page'), findsOneWidget);

        testDelegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsNothing);
      },
    );
  });
}
