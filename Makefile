# Makefile for Event Marketplace App

.PHONY: help install test build deploy clean dev docker-up docker-down

# Default target
help:
	@echo "Event Marketplace App - Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  install     Install dependencies"
	@echo "  dev         Start development server"
	@echo "  clean       Clean build artifacts"
	@echo ""
	@echo "Testing:"
	@echo "  test        Run all tests"
	@echo "  test-unit   Run unit tests only"
	@echo "  test-integration Run integration tests only"
	@echo "  test-widget Run widget tests only"
	@echo "  format      Check code formatting"
	@echo "  analyze     Run static analysis"
	@echo ""
	@echo "Building:"
	@echo "  build       Build for production"
	@echo "  build-web   Build web version"
	@echo "  build-android Build Android APK"
	@echo "  build-ios   Build iOS app"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy      Deploy to Firebase"
	@echo "  deploy-docker Deploy with Docker"
	@echo "  deploy-all  Deploy to all platforms"
	@echo ""
	@echo "Docker:"
	@echo "  docker-up   Start Docker containers"
	@echo "  docker-down Stop Docker containers"
	@echo "  docker-build Build Docker image"
	@echo ""
	@echo "Utilities:"
	@echo "  lint        Run linting"
	@echo "  coverage    Generate coverage report"
	@echo "  security    Run security checks"

# Development commands
install:
	@echo "Installing dependencies..."
	flutter pub get

dev:
	@echo "Starting development server..."
	flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

clean:
	@echo "Cleaning build artifacts..."
	flutter clean
	rm -rf build/
	rm -rf coverage/

# Testing commands
test: install
	@echo "Running all tests..."
	chmod +x scripts/test.sh
	./scripts/test.sh --type all

test-unit: install
	@echo "Running unit tests..."
	chmod +x scripts/test.sh
	./scripts/test.sh --type unit

test-integration: install
	@echo "Running integration tests..."
	chmod +x scripts/test.sh
	./scripts/test.sh --type integration

test-widget: install
	@echo "Running widget tests..."
	chmod +x scripts/test.sh
	./scripts/test.sh --type widget

format:
	@echo "Checking code formatting..."
	flutter format --dry-run --set-exit-if-changed .

format-fix:
	@echo "Fixing code formatting..."
	flutter format .

analyze:
	@echo "Running static analysis..."
	flutter analyze

lint: format analyze

# Building commands
build: install
	@echo "Building for production..."
	flutter build web --release

build-web: install
	@echo "Building web version..."
	flutter build web --release

build-android: install
	@echo "Building Android APK..."
	flutter build apk --release

build-ios: install
	@echo "Building iOS app..."
	flutter build ios --release --no-codesign

# Deployment commands
deploy: build
	@echo "Deploying to Firebase..."
	chmod +x scripts/deploy.sh
	./scripts/deploy.sh --platform web

deploy-docker: build
	@echo "Deploying with Docker..."
	chmod +x scripts/deploy.sh
	./scripts/deploy.sh --platform docker

deploy-all: build
	@echo "Deploying to all platforms..."
	chmod +x scripts/deploy.sh
	./scripts/deploy.sh --platform all

# Docker commands
docker-up:
	@echo "Starting Docker containers..."
	docker-compose up -d

docker-down:
	@echo "Stopping Docker containers..."
	docker-compose down

docker-build:
	@echo "Building Docker image..."
	docker build -t event-marketplace-app .

docker-dev:
	@echo "Starting development with Docker..."
	docker-compose up dev

# Utility commands
coverage: test-unit
	@echo "Generating coverage report..."
	genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report generated in coverage/html/"

security:
	@echo "Running security checks..."
	chmod +x scripts/test.sh
	./scripts/test.sh --type security

# Firebase commands
firebase-init:
	@echo "Initializing Firebase..."
	firebase init

firebase-emulator:
	@echo "Starting Firebase emulator..."
	firebase emulators:start

firebase-deploy:
	@echo "Deploying to Firebase..."
	firebase deploy

# CI/CD commands
ci-test:
	@echo "Running CI tests..."
	flutter pub get
	flutter analyze
	flutter test --coverage
	flutter build web --release

ci-deploy:
	@echo "Running CI deployment..."
	firebase deploy --only hosting

# Development setup
setup:
	@echo "Setting up development environment..."
	flutter doctor
	flutter pub get
	@echo "Development environment setup complete!"

# Production setup
prod-setup:
	@echo "Setting up production environment..."
	flutter clean
	flutter pub get
	flutter build web --release
	@echo "Production environment setup complete!"

# Monitoring
monitor:
	@echo "Starting monitoring services..."
	docker-compose up prometheus grafana -d
	@echo "Monitoring services started!"
	@echo "Prometheus: http://localhost:9090"
	@echo "Grafana: http://localhost:3001 (admin/admin)"

# Backup
backup:
	@echo "Creating backup..."
	tar -czf backup-$(shell date +%Y%m%d-%H%M%S).tar.gz \
		--exclude=build \
		--exclude=coverage \
		--exclude=.dart_tool \
		--exclude=node_modules \
		.
	@echo "Backup created!"

# Restore
restore:
	@echo "Available backups:"
	@ls -la backup-*.tar.gz 2>/dev/null || echo "No backups found"
	@echo "To restore, run: tar -xzf backup-YYYYMMDD-HHMMSS.tar.gz"
