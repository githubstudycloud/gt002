# 部署与DevOps完整指南

## 1. 容器化最佳实践

### 1.1 Dockerfile优化

#### Java应用多阶段构建
```dockerfile
# 构建阶段
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# 创建非root用户
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# 复制jar包
COPY --from=builder /app/target/*.jar app.jar

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", \
  "-XX:+UseG1GC", \
  "-XX:MaxRAMPercentage=75.0", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/tmp/heapdump.hprof", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
```

#### Go应用最小化镜像
```dockerfile
# 构建阶段
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o main .

# 运行阶段 - 使用distroless或scratch
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/main /
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/main"]

# 最终镜像大小: ~15MB
```

#### Python应用优化
```dockerfile
FROM python:3.12-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# 运行阶段
FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache /wheels/*

COPY . .
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### Rust应用极致优化
```dockerfile
FROM rust:1.75-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

# 使用scratch最小化镜像
FROM scratch
COPY --from=builder /app/target/release/app /
EXPOSE 8080
ENTRYPOINT ["/app"]

# 最终镜像大小: ~5MB
```

---

### 1.2 Docker Compose本地开发环境

```yaml
version: '3.8'

services:
  # 后端服务
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      - ./backend:/app
      - /app/target  # 缓存构建产物
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-network

  # 前端服务
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules  # 避免主机node_modules覆盖
    environment:
      - VITE_API_URL=http://localhost:8080
    networks:
      - app-network

  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - app-network

  # Kafka
  kafka:
    image: bitnami/kafka:3.6
    ports:
      - "9092:9092"
    environment:
      - KAFKA_CFG_NODE_ID=0
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka:9093
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
    volumes:
      - kafka-data:/bitnami/kafka
    networks:
      - app-network

  # Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - es-data:/usr/share/elasticsearch/data
    networks:
      - app-network

  # 监控 - Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - app-network

  # 监控 - Grafana
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - app-network

volumes:
  postgres-data:
  redis-data:
  kafka-data:
  es-data:
  prometheus-data:
  grafana-data:

networks:
  app-network:
    driver: bridge
```

---

## 2. Kubernetes部署

### 2.1 应用部署配置

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: production
  labels:
    app: backend-api
    version: v1.2.3
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # 零停机部署
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
        version: v1.2.3
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      # Pod反亲和性 - 分散到不同节点
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - backend-api
              topologyKey: kubernetes.io/hostname

      # 容器配置
      containers:
      - name: backend-api
        image: myregistry.com/backend-api:v1.2.3
        imagePullPolicy: IfNotPresent

        ports:
        - name: http
          containerPort: 8080
          protocol: TCP

        # 资源限制
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"

        # 环境变量
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace

        # 健康检查
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3

        # 启动探针（防止慢启动被kill）
        startupProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 30  # 最多等待150秒

        # 优雅关闭
        lifecycle:
          preStop:
            exec:
              command: ["sh", "-c", "sleep 15"]  # 等待负载均衡摘除

        # 挂载配置
        volumeMounts:
        - name: config
          mountPath: /app/config
        - name: logs
          mountPath: /app/logs

      # 卷定义
      volumes:
      - name: config
        configMap:
          name: backend-config
      - name: logs
        emptyDir: {}

      # 镜像拉取凭证
      imagePullSecrets:
      - name: registry-secret

      # 终止宽限期（优雅关闭）
      terminationGracePeriodSeconds: 30
```

#### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-api
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: backend-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None
```

#### Ingress (NGINX)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-api
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"  # 限流
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-api
            port:
              number: 80
```

#### HorizontalPodAutoscaler (自动伸缩)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-api
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-api
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # 5分钟稳定窗口
      policies:
      - type: Percent
        value: 50  # 每次最多缩容50%
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100  # 每次最多扩容100%
        periodSeconds: 30
      - type: Pods
        value: 4  # 或者一次性增加4个Pod
        periodSeconds: 30
      selectPolicy: Max
```

#### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
data:
  application.yml: |
    server:
      port: 8080
      shutdown: graceful
    spring:
      datasource:
        url: jdbc:postgresql://postgres-service:5432/myapp
        username: myapp
        hikari:
          maximum-pool-size: 20
          minimum-idle: 5
      redis:
        host: redis-service
        port: 6379
    management:
      endpoints:
        web:
          exposure:
            include: health,info,prometheus
```

#### Secret (Base64编码)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: production
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # 实际使用Sealed Secrets或External Secrets
```

---

### 2.2 Helm Chart模板

#### Chart.yaml
```yaml
apiVersion: v2
name: backend-api
description: Backend API Service
type: application
version: 1.0.0
appVersion: "1.2.3"
```

#### values.yaml
```yaml
replicaCount: 3

image:
  repository: myregistry.com/backend-api
  pullPolicy: IfNotPresent
  tag: ""  # 默认使用appVersion

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls-secret
      hosts:
        - api.example.com

resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2000m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

config:
  springProfilesActive: production
  databaseUrl: postgresql://postgres:5432/myapp
```

#### templates/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "backend-api.fullname" . }}
  labels:
    {{- include "backend-api.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "backend-api.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "backend-api.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

#### 部署命令
```bash
# 安装/升级
helm upgrade --install backend-api ./backend-api \
  --namespace production \
  --create-namespace \
  --values values-prod.yaml \
  --set image.tag=v1.2.3 \
  --wait --timeout 5m

# 回滚
helm rollback backend-api 1 --namespace production

# 查看历史
helm history backend-api --namespace production
```

---

## 3. CI/CD流水线

### 3.1 GitHub Actions

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # 代码检查与测试
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: maven

      - name: Run tests
        run: mvn clean test

      - name: Code coverage
        run: mvn jacoco:report

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3

      - name: SonarQube Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn sonar:sonar \
            -Dsonar.projectKey=my-project \
            -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }}

  # 安全扫描
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  # 构建与推送镜像
  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      version: ${{ steps.meta.outputs.version }}
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha,prefix={{branch}}-

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'

  # 部署到测试环境
  deploy-test:
    needs: build
    runs-on: ubuntu-latest
    environment: test
    steps:
      - name: Deploy to Test Cluster
        uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s/test/deployment.yaml
            k8s/test/service.yaml
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build.outputs.version }}
          namespace: test

  # 部署到生产环境（需要手动审批）
  deploy-prod:
    needs: [build, deploy-test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.example.com
    steps:
      - name: Deploy to Production Cluster
        uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s/prod/deployment.yaml
            k8s/prod/service.yaml
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build.outputs.version }}
          namespace: production
          strategy: canary
          percentage: 20

      - name: Wait for approval
        run: sleep 300  # 5分钟金丝雀观察

      - name: Promote to 100%
        uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s/prod/deployment.yaml
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build.outputs.version }}
          namespace: production
          strategy: canary
          percentage: 100
```

---

### 3.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy-test
  - deploy-prod

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

# 测试阶段
test:unit:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  services:
    - postgres:16
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
  script:
    - mvn clean test
    - mvn jacoco:report
  coverage: '/Total.*?([0-9]{1,3})%/'
  artifacts:
    reports:
      junit: target/surefire-reports/TEST-*.xml
      coverage_report:
        coverage_format: cobertura
        path: target/site/jacoco/jacoco.xml

test:sonar:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn sonar:sonar
  only:
    - main
    - develop

# 构建阶段
build:docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
    # 额外推送latest标签
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop

build:scan:
  stage: build
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL $IMAGE_TAG
  allow_failure: true

# 部署到测试环境
deploy:test:
  stage: deploy-test
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context test-cluster
    - kubectl set image deployment/backend-api backend-api=$IMAGE_TAG -n test
    - kubectl rollout status deployment/backend-api -n test --timeout=5m
  environment:
    name: test
    url: https://test-api.example.com
  only:
    - develop

# 部署到生产环境
deploy:prod:canary:
  stage: deploy-prod
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context prod-cluster
    # 金丝雀发布 - 20%流量
    - kubectl apply -f k8s/prod/canary-deployment.yaml
    - kubectl set image deployment/backend-api-canary backend-api=$IMAGE_TAG -n production
    - kubectl rollout status deployment/backend-api-canary -n production --timeout=5m
  environment:
    name: production-canary
  when: manual
  only:
    - main

deploy:prod:full:
  stage: deploy-prod
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context prod-cluster
    # 全量发布
    - kubectl set image deployment/backend-api backend-api=$IMAGE_TAG -n production
    - kubectl rollout status deployment/backend-api -n production --timeout=10m
    # 删除金丝雀部署
    - kubectl delete deployment backend-api-canary -n production --ignore-not-found
  environment:
    name: production
    url: https://api.example.com
  when: manual
  only:
    - main
```

---

## 4. 发布策略实战

### 4.1 蓝绿部署脚本

```bash
#!/bin/bash
# blue-green-deploy.sh

set -e

NAMESPACE="production"
SERVICE_NAME="backend-api"
NEW_VERSION=$1
CURRENT_ENV=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.env}')

if [ "$CURRENT_ENV" == "blue" ]; then
  NEW_ENV="green"
else
  NEW_ENV="blue"
fi

echo "Current environment: $CURRENT_ENV"
echo "Deploying to: $NEW_ENV"

# 部署新版本到非活跃环境
kubectl set image deployment/${SERVICE_NAME}-${NEW_ENV} \
  ${SERVICE_NAME}=myregistry.com/${SERVICE_NAME}:${NEW_VERSION} \
  -n $NAMESPACE

# 等待部署完成
kubectl rollout status deployment/${SERVICE_NAME}-${NEW_ENV} -n $NAMESPACE --timeout=5m

# 健康检查
echo "Running health checks..."
for i in {1..10}; do
  if kubectl exec -n $NAMESPACE deployment/${SERVICE_NAME}-${NEW_ENV} -- \
    wget -q -O- http://localhost:8080/actuator/health | grep -q "UP"; then
    echo "Health check passed"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "Health check failed"
    exit 1
  fi
  sleep 10
done

# 切换流量
echo "Switching traffic to $NEW_ENV..."
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"env\":\"$NEW_ENV\"}}}"

echo "Deployment successful. Old environment ($CURRENT_ENV) is still running for rollback."
echo "To rollback: kubectl patch service $SERVICE_NAME -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"env\":\"$CURRENT_ENV\"}}}'"
```

---

### 4.2 金丝雀发布（使用Flagger）

```yaml
# canary.yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: backend-api
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-api
  service:
    port: 80
    targetPort: 8080
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
    webhooks:
    - name: load-test
      url: http://flagger-loadtester.test/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://backend-api-canary.production/"
```

---

## 5. 配置管理实战

### 5.1 使用Apollo配置中心

#### Docker Compose部署Apollo
```yaml
version: '3.8'
services:
  apollo-db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: ApolloConfigDB
    volumes:
      - ./sql/apolloconfigdb.sql:/docker-entrypoint-initdb.d/apolloconfigdb.sql

  apollo-configservice:
    image: apolloconfig/apollo-configservice:latest
    depends_on:
      - apollo-db
    environment:
      spring_datasource_url: jdbc:mysql://apollo-db:3306/ApolloConfigDB?characterEncoding=utf8
      spring_datasource_username: root
      spring_datasource_password: password
    ports:
      - "8080:8080"

  apollo-adminservice:
    image: apolloconfig/apollo-adminservice:latest
    depends_on:
      - apollo-db
    environment:
      spring_datasource_url: jdbc:mysql://apollo-db:3306/ApolloConfigDB?characterEncoding=utf8
      spring_datasource_username: root
      spring_datasource_password: password
    ports:
      - "8090:8090"

  apollo-portal:
    image: apolloconfig/apollo-portal:latest
    depends_on:
      - apollo-configservice
      - apollo-adminservice
    environment:
      apollo_portal_envs: dev,test,prod
      dev_meta: http://apollo-configservice:8080
    ports:
      - "8070:8070"
```

#### Java应用集成Apollo
```java
// application.properties
app.id=backend-api
apollo.meta=http://apollo-configservice:8080
apollo.bootstrap.enabled=true
apollo.bootstrap.namespaces=application,database,redis

// 使用配置
@Component
public class ConfigService {
    @Value("${redis.max.connections:10}")
    private int redisMaxConnections;

    @ApolloConfig
    private Config config;

    @ApolloConfigChangeListener
    private void onChange(ConfigChangeEvent changeEvent) {
        for (String key : changeEvent.changedKeys()) {
            log.info("Config changed: {} = {}", key, changeEvent.getChange(key).getNewValue());
        }
    }
}
```

---

### 5.2 使用Nacos配置中心

```yaml
# Docker Compose部署Nacos
version: '3.8'
services:
  nacos:
    image: nacos/nacos-server:v2.3.0
    environment:
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=mysql
      - MYSQL_SERVICE_DB_NAME=nacos
      - MYSQL_SERVICE_USER=nacos
      - MYSQL_SERVICE_PASSWORD=nacos
    ports:
      - "8848:8848"
      - "9848:9848"
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=nacos
      - MYSQL_USER=nacos
      - MYSQL_PASSWORD=nacos
    volumes:
      - ./nacos-mysql:/var/lib/mysql
```

---

## 6. 监控与告警

### 6.1 Prometheus配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets: ['alertmanager:9093']

rule_files:
  - '/etc/prometheus/rules/*.yml'

scrape_configs:
  # Kubernetes服务发现
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
      target_label: __address__

  # 应用指标
  - job_name: 'backend-api'
    static_configs:
    - targets: ['backend-api:8080']
    metrics_path: '/actuator/prometheus'
```

### 6.2 告警规则

```yaml
# alerts/backend.yml
groups:
- name: backend_api
  interval: 30s
  rules:
  # 高错误率
  - alert: HighErrorRate
    expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "{{ $labels.instance }} error rate is {{ $value }}%"

  # 高延迟
  - alert: HighLatency
    expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High latency detected"
      description: "P95 latency is {{ $value }}s"

  # 服务不可用
  - alert: ServiceDown
    expr: up{job="backend-api"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service is down"
      description: "{{ $labels.instance }} is unreachable"

  # 高内存使用
  - alert: HighMemoryUsage
    expr: (process_resident_memory_bytes / node_memory_MemTotal_bytes) > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Memory usage is {{ $value | humanizePercentage }}"

  # Pod重启频繁
  - alert: PodRestartingTooOften
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod restarting too often"
      description: "{{ $labels.namespace }}/{{ $labels.pod }} restarting frequently"
```

---

这份部署和DevOps指南涵盖了从容器化、Kubernetes部署、CI/CD流水线到配置管理和监控的完整实践。每个部分都提供了生产级的配置示例，可以直接应用到实际项目中。