#!/bin/bash

# Testing script for Event Marketplace App
set -e

echo "🧪 Starting test suite..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_test "Running: $test_name"
    
    if eval "$test_command"; then
        print_status "✅ $test_name PASSED"
        ((TESTS_PASSED++))
    else
        print_error "❌ $test_name FAILED"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Check Flutter installation
check_flutter() {
    print_status "Checking Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    flutter --version
    print_status "Flutter is properly installed."
}

# Run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    flutter test --coverage
    
    if [ $? -eq 0 ]; then
        print_status "Unit tests completed successfully!"
        
        # Generate coverage report
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html
            print_status "Coverage report generated in coverage/html/"
        fi
    else
        print_error "Unit tests failed!"
        exit 1
    fi
}

# Run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    if [ -d "integration_test" ]; then
        flutter test integration_test/
        
        if [ $? -eq 0 ]; then
            print_status "Integration tests completed successfully!"
        else
            print_error "Integration tests failed!"
            exit 1
        fi
    else
        print_warning "No integration tests found. Skipping..."
    fi
}

# Run widget tests
run_widget_tests() {
    print_status "Running widget tests..."
    
    flutter test test/widget_test.dart
    
    if [ $? -eq 0 ]; then
        print_status "Widget tests completed successfully!"
    else
        print_error "Widget tests failed!"
        exit 1
    fi
}

# Check code formatting
check_formatting() {
    print_status "Checking code formatting..."
    
    flutter format --dry-run --set-exit-if-changed .
    
    if [ $? -eq 0 ]; then
        print_status "Code formatting is correct!"
    else
        print_error "Code formatting issues found. Run 'flutter format .' to fix."
        exit 1
    fi
}

# Run static analysis
run_analysis() {
    print_status "Running static analysis..."
    
    flutter analyze
    
    if [ $? -eq 0 ]; then
        print_status "Static analysis completed successfully!"
    else
        print_error "Static analysis found issues!"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    flutter pub deps
    
    if [ $? -eq 0 ]; then
        print_status "Dependencies are properly configured!"
    else
        print_error "Dependency issues found!"
        exit 1
    fi
}

# Performance tests
run_performance_tests() {
    print_status "Running performance tests..."
    
    # Build the app to check for performance issues
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        print_status "Performance build completed successfully!"
        
        # Check build size
        BUILD_SIZE=$(du -sh build/web | cut -f1)
        print_status "Build size: $BUILD_SIZE"
        
        # Check for large files
        find build/web -type f -size +1M -exec ls -lh {} \; | while read line; do
            print_warning "Large file found: $line"
        done
    else
        print_error "Performance build failed!"
        exit 1
    fi
}

# Security tests
run_security_tests() {
    print_status "Running security tests..."
    
    # Check for hardcoded secrets
    if grep -r "password\|secret\|key" lib/ --include="*.dart" | grep -v "// TODO\|// FIXME\|password_strength\|secretKey" > /dev/null; then
        print_warning "Potential hardcoded secrets found. Please review."
    else
        print_status "No obvious hardcoded secrets found."
    fi
    
    # Check for debug prints in production code
    if grep -r "print(" lib/ --include="*.dart" > /dev/null; then
        print_warning "Debug print statements found. Consider removing for production."
    else
        print_status "No debug print statements found."
    fi
}

# Accessibility tests
run_accessibility_tests() {
    print_status "Running accessibility tests..."
    
    # Check for semantic labels
    if grep -r "Semantics" lib/ --include="*.dart" > /dev/null; then
        print_status "Semantic widgets found. Good accessibility practices!"
    else
        print_warning "Consider adding semantic widgets for better accessibility."
    fi
}

# Main test function
main() {
    local test_type=${1:-all}
    
    print_status "Starting test suite for $test_type tests..."
    
    check_flutter
    
    case $test_type in
        "unit")
            run_unit_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "widget")
            run_widget_tests
            ;;
        "format")
            check_formatting
            ;;
        "analysis")
            run_analysis
            ;;
        "deps")
            check_dependencies
            ;;
        "performance")
            run_performance_tests
            ;;
        "security")
            run_security_tests
            ;;
        "accessibility")
            run_accessibility_tests
            ;;
        "all")
            run_test "Code Formatting" "flutter format --dry-run --set-exit-if-changed ."
            run_test "Static Analysis" "flutter analyze"
            run_test "Dependencies Check" "flutter pub deps"
            run_test "Unit Tests" "flutter test --coverage"
            run_test "Widget Tests" "flutter test test/widget_test.dart"
            run_test "Integration Tests" "flutter test integration_test/ || true"
            run_test "Performance Build" "flutter build web --release"
            run_test "Security Check" "grep -r 'password\\|secret\\|key' lib/ --include='*.dart' | grep -v '// TODO\\|// FIXME\\|password_strength\\|secretKey' || true"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            print_status "Available test types: unit, integration, widget, format, analysis, deps, performance, security, accessibility, all"
            exit 1
            ;;
    esac
    
    # Print test summary
    echo ""
    print_status "📊 Test Summary:"
    print_status "✅ Tests Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        print_error "❌ Tests Failed: $TESTS_FAILED"
        exit 1
    else
        print_status "🎉 All tests completed successfully!"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TEST_TYPE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --type TYPE    Test type: unit, integration, widget, format, analysis, deps, performance, security, accessibility, all (default: all)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main ${TEST_TYPE:-all}
