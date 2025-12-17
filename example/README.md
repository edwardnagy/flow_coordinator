# Books App Example

An example Books App demonstrating the capabilities of the package.

## Features

- **Deep Linking**: Routes can be navigated directly via URI (e.g., `/books/new`,
 `/books/123`, `/settings`).
- **Sign-in Routing**: Authentication state determines whether the login screen
or home screen is displayed. Unauthenticated deep links redirect to login.
- **Nested Routing**: The home flow manages a tab-based navigation structure with
the books flow and settings as separate tabs.
- **Stack Skipping**: Selecting a random book from the settings screen navigates
directly to that book in the books flow, bypassing the books list.
