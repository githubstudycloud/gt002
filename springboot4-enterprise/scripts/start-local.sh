#!/bin/bash

# Start local development environment
# Usage: ./start-local.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Local Development Environment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Start infrastructure services
echo -e "${YELLOW}Starting infrastructure services with Docker Compose...${NC}"
cd deployment/docker
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"

check_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✓ $service is ready${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    echo -e "${RED}✗ $service failed to start${NC}"
    return 1
}

check_service "PostgreSQL" 5432
check_service "Redis" 6379
check_service "Kafka" 9092
check_service "Prometheus" 9090
check_service "Grafana" 3000

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Infrastructure services are ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Service URLs:${NC}"
echo "  PostgreSQL:  localhost:5432"
echo "  Redis:       localhost:6379"
echo "  MongoDB:     localhost:27017"
echo "  Kafka:       localhost:9092"
echo "  Prometheus:  http://localhost:9090"
echo "  Grafana:     http://localhost:3000 (admin/admin)"
echo "  Jaeger:      http://localhost:16686"
echo "  Kafka UI:    http://localhost:8090"
echo "  Nacos:       http://localhost:8848/nacos (nacos/nacos)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start services with: cd <service-dir> && mvn spring-boot:run"
echo "  2. Access API docs: http://localhost:8080/swagger-ui.html"
echo "  3. Stop infrastructure: cd deployment/docker && docker-compose down"
