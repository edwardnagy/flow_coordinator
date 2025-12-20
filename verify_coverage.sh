#!/bin/bash

# Test Coverage Verification Script for Flow Coordinator Package
# This script runs tests and verifies coverage reaches 100%

set -e  # Exit on error

echo "=========================================="
echo "Flow Coordinator Test Coverage Verification"
echo "=========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ Flutter found: $(flutter --version | head -1)"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
echo "✓ Dependencies installed"
echo ""

# Run tests with coverage
echo "Running tests with coverage..."
flutter test --coverage --no-pub
echo "✓ Tests completed"
echo ""

# Check if coverage file exists
if [ ! -f "coverage/lcov.info" ]; then
    echo "ERROR: Coverage file not generated"
    exit 1
fi

echo "✓ Coverage data generated"
echo ""

# Count test results
echo "Test Statistics:"
TEST_COUNT=$(grep -r "^\s*test\|^\s*testWidgets" test/ | wc -l)
echo "  Total test cases: $TEST_COUNT"
TEST_FILES=$(find test -name "*_test.dart" | wc -l)
echo "  Total test files: $TEST_FILES"
echo ""

# Display coverage summary (if lcov is installed)
if command -v lcov &> /dev/null; then
    echo "Coverage Summary:"
    lcov --summary coverage/lcov.info 2>&1 | grep -E "lines|functions|branches" || true
    echo ""
    
    # Generate HTML report
    echo "Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html --quiet
    echo "✓ HTML report generated at: coverage/html/index.html"
    echo ""
    
    # Try to open the report
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open coverage/html/index.html 2>/dev/null || true
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open coverage/html/index.html 2>/dev/null || true
    fi
else
    echo "Note: Install lcov for detailed coverage analysis"
    echo "  macOS: brew install lcov"
    echo "  Ubuntu/Debian: sudo apt-get install lcov"
    echo ""
fi

# Count covered files
COVERED_FILES=$(grep -c "^SF:" coverage/lcov.info)
echo "Coverage Statistics:"
echo "  Files with coverage: $COVERED_FILES"
echo ""

# Extract line coverage percentage
if command -v lcov &> /dev/null; then
    LINE_COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
    if [ ! -z "$LINE_COVERAGE" ]; then
        echo "  Line Coverage: $LINE_COVERAGE"
        
        # Check if coverage is 100%
        if [[ "$LINE_COVERAGE" == "100.0%" ]]; then
            echo ""
            echo "=========================================="
            echo "✓ SUCCESS: 100% Test Coverage Achieved!"
            echo "=========================================="
        else
            echo ""
            echo "=========================================="
            echo "⚠ Coverage is not 100%: $LINE_COVERAGE"
            echo "=========================================="
            echo ""
            echo "To identify uncovered code:"
            echo "  1. Open coverage/html/index.html in a browser"
            echo "  2. Look for files with coverage < 100%"
            echo "  3. Add tests for uncovered lines"
        fi
    fi
fi

echo ""
echo "Coverage report location: coverage/lcov.info"
echo "HTML report location: coverage/html/index.html"
echo ""
echo "Done!"
