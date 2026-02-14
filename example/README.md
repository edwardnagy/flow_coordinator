# Books App Example

A demo app that shows how to use the `flow_coordinator` package for real-world
navigation scenarios.

## Running the Example

```bash
cd example
flutter create .
flutter run
```

On web, use `flutter run -d chrome` to see browser URL updates in action.

## Flow Hierarchy

```text
App
└── RootFlowCoordinator
    ├── LoginScreen (unauthenticated)
    └── HomeFlowCoordinator (authenticated)
        ├── BooksFlowCoordinator (tab)
        │   ├── BookListScreen
        │   └── BookDetailsScreen
        └── SettingsScreen (tab)
```

## Demonstrated Features

- **Deep Linking:** Routes can be navigated directly via URI (e.g., `/books/new`,
`/books/123`, `/settings`).
- **Authentication Guard:** The root flow coordinator redirects to the login
screen when unauthenticated and preserves deep links for after sign-in.
- **Tabbed Navigation:** The home flow manages a tab bar with the books flow and
settings as separate tabs, each wrapped in a `FlowRouteScope`.
- **Programmatic Deep Links:** Selecting a random book from the settings screen
uses `setNewRouteInformation` to trigger `onNewRouteInformation` on the home flow
coordinator, which then forwards the route to the books flow.
- **Browser URL Sync:** The browser's address bar reflects the current navigation
state and updates as the user navigates, including when using back buttons.
