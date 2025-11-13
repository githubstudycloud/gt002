#!/bin/bash

# Smoke tests for production deployment
# Usage: ./smoke-test.sh <base-url>

set -e

BASE_URL=${1:-"http://localhost:8080"}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED_TESTS=0
PASSED_TESTS=0

test_endpoint() {
    local name=$1
    local endpoint=$2
    local expected_status=${3:-200}

    echo -ne "${YELLOW}Testing $name... ${NC}"

    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")

    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $status_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $status_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Running Smoke Tests${NC}"
echo -e "${GREEN}Base URL: $BASE_URL${NC}"
echo -e "${GREEN}========================================${NC}"

# Test Gateway
test_endpoint "Gateway Health" "/actuator/health"
test_endpoint "Gateway Info" "/actuator/info"

# Test User Service
test_endpoint "User Service Health" "/api/v1/users/actuator/health"
test_endpoint "Get Users" "/api/v1/users"

# Test Order Service
test_endpoint "Order Service Health" "/api/v1/orders/actuator/health"

# Test Product Service
test_endpoint "Product Service Health" "/api/v1/products/actuator/health"

# Test API Documentation
test_endpoint "Swagger UI" "/swagger-ui.html"
test_endpoint "OpenAPI Spec" "/v3/api-docs"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Results${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Smoke tests FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All smoke tests PASSED${NC}"
    exit 0
fi
