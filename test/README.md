## Running Tests

To run all tests:

```bash
flutter test
```

To run tests with coverage:

```bash
flutter test --coverage
```

To view coverage report:

```bash
# Install lcov if not already installed
# On Ubuntu/Debian: sudo apt-get install lcov
# On macOS: brew install lcov

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open the report in a browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```
