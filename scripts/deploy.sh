#!/bin/bash

# Deployment script for Event Marketplace App
set -e

echo "🚀 Starting deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install Firebase CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Docker deployment will be skipped."
    fi
    
    print_status "All dependencies are satisfied."
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    flutter test --coverage
    
    if [ $? -eq 0 ]; then
        print_status "All tests passed!"
    else
        print_error "Tests failed. Deployment aborted."
        exit 1
    fi
}

# Build the application
build_app() {
    print_status "Building application..."
    
    # Clean previous builds
    flutter clean
    flutter pub get
    
    # Build for web
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        print_status "Web build completed successfully!"
    else
        print_error "Web build failed."
        exit 1
    fi
    
    # Build for Android (if needed)
    if [ "$1" = "--android" ]; then
        print_status "Building Android APK..."
        flutter build apk --release
        
        if [ $? -eq 0 ]; then
            print_status "Android build completed successfully!"
        else
            print_error "Android build failed."
            exit 1
        fi
    fi
}

# Deploy to Firebase
deploy_firebase() {
    print_status "Deploying to Firebase..."
    
    firebase deploy --only hosting
    
    if [ $? -eq 0 ]; then
        print_status "Firebase deployment completed successfully!"
    else
        print_error "Firebase deployment failed."
        exit 1
    fi
}

# Deploy with Docker
deploy_docker() {
    if command -v docker &> /dev/null; then
        print_status "Building Docker image..."
        
        docker build -t event-marketplace-app .
        
        if [ $? -eq 0 ]; then
            print_status "Docker image built successfully!"
            
            # Run container
            docker run -d -p 8080:80 --name event-marketplace-app event-marketplace-app
            
            if [ $? -eq 0 ]; then
                print_status "Docker container started successfully!"
                print_status "Application is available at http://localhost:8080"
            else
                print_error "Failed to start Docker container."
                exit 1
            fi
        else
            print_error "Docker build failed."
            exit 1
        fi
    else
        print_warning "Docker not available. Skipping Docker deployment."
    fi
}

# Main deployment function
main() {
    local environment=${1:-production}
    local platform=${2:-web}
    
    print_status "Starting deployment for $environment environment on $platform platform..."
    
    check_dependencies
    run_tests
    build_app $platform
    
    case $platform in
        "web")
            deploy_firebase
            ;;
        "docker")
            deploy_docker
            ;;
        "all")
            deploy_firebase
            deploy_docker
            ;;
        *)
            print_error "Unknown platform: $platform"
            print_status "Available platforms: web, docker, all"
            exit 1
            ;;
    esac
    
    print_status "🎉 Deployment completed successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --android)
            ANDROID=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --environment ENV    Deployment environment (default: production)"
            echo "  --platform PLATFORM  Deployment platform: web, docker, all (default: web)"
            echo "  --android           Build Android APK"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main ${ENVIRONMENT:-production} ${PLATFORM:-web}
