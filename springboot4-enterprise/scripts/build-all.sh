#!/bin/bash

# Build all services script
# Usage: ./build-all.sh [options]
# Options:
#   -s, --skip-tests    Skip running tests
#   -c, --clean         Clean before build
#   -d, --docker        Build Docker images

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
SKIP_TESTS=false
CLEAN=false
BUILD_DOCKER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -d|--docker)
            BUILD_DOCKER=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Spring Boot 4 Enterprise${NC}"
echo -e "${GREEN}========================================${NC}"

# Build Maven command
MVN_CMD="mvn"

if [ "$CLEAN" = true ]; then
    MVN_CMD="$MVN_CMD clean"
fi

MVN_CMD="$MVN_CMD install"

if [ "$SKIP_TESTS" = true ]; then
    MVN_CMD="$MVN_CMD -DskipTests"
fi

echo -e "${YELLOW}Executing: $MVN_CMD${NC}"
$MVN_CMD

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Build Docker images if requested
if [ "$BUILD_DOCKER" = true ]; then
    echo -e "${YELLOW}Building Docker images...${NC}"

    SERVICES=("gateway-service" "user-service" "order-service" "product-service")

    for service in "${SERVICES[@]}"; do
        echo -e "${YELLOW}Building Docker image for $service${NC}"

        if [ -d "infrastructure/$service" ]; then
            cd "infrastructure/$service"
        elif [ -d "modules/$service" ]; then
            cd "modules/$service"
        else
            echo -e "${RED}Service directory not found: $service${NC}"
            continue
        fi

        mvn jib:dockerBuild
        cd ../..

        echo -e "${GREEN}✓ $service image built${NC}"
    done
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All builds completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
