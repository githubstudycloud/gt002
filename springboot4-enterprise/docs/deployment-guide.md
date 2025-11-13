# 部署运维手册

## 部署架构

### 环境划分

1. **开发环境 (Development)**
   - 用途：日常开发和功能测试
   - 基础设施：Docker Compose 或 Minikube
   - 数据：测试数据

2. **预生产环境 (Staging)**
   - 用途：发布前验证
   - 基础设施：Kubernetes 集群
   - 数据：匿名化生产数据

3. **生产环境 (Production)**
   - 用途：正式服务
   - 基础设施：Kubernetes 集群（多可用区）
   - 数据：真实数据

## Kubernetes 部署

### 前置要求

```bash
# 安装 kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 安装 Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 验证安装
kubectl version --client
helm version
```

### 配置 kubectl

```bash
# 设置 kubeconfig
export KUBECONFIG=~/.kube/config

# 查看集群信息
kubectl cluster-info

# 查看节点
kubectl get nodes
```

### 部署流程

#### 1. 创建命名空间

```bash
kubectl apply -f deployment/kubernetes/base/namespace.yaml
```

#### 2. 创建 Secrets

```bash
# 从文件创建（生产环境建议使用 Sealed Secrets 或 External Secrets）
kubectl create secret generic enterprise-secrets \
  --from-literal=DATABASE_PASSWORD='your-secure-password' \
  --from-literal=JWT_SECRET='your-jwt-secret' \
  --from-literal=REDIS_PASSWORD='your-redis-password' \
  -n enterprise-app

# 或者应用 YAML 文件（需要先进行 base64 编码）
kubectl apply -f deployment/kubernetes/base/secret.yaml
```

#### 3. 创建 ConfigMap

```bash
kubectl apply -f deployment/kubernetes/base/configmap.yaml
```

#### 4. 部署数据库和中间件

```bash
# PostgreSQL (使用 Helm Chart)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql \
  --namespace enterprise-app \
  --set auth.username=enterprise \
  --set auth.password=enterprise123 \
  --set auth.database=enterprise_db

# Redis
helm install redis bitnami/redis \
  --namespace enterprise-app \
  --set auth.password=redis123

# Kafka
helm install kafka bitnami/kafka \
  --namespace enterprise-app \
  --set replicaCount=3
```

#### 5. 部署应用服务

```bash
# Gateway Service
kubectl apply -f deployment/kubernetes/base/gateway-deployment.yaml

# User Service
kubectl apply -f deployment/kubernetes/base/user-service-deployment.yaml

# 验证部署状态
kubectl get deployments -n enterprise-app
kubectl get pods -n enterprise-app
kubectl get services -n enterprise-app
```

#### 6. 配置 Ingress

```bash
# 安装 Nginx Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# 应用 Ingress 规则
kubectl apply -f deployment/kubernetes/base/gateway-deployment.yaml
```

### 使用 Helm 部署

#### 创建 Helm Chart

```bash
cd deployment/helm
helm create enterprise-app
```

#### 自定义 values.yaml

```yaml
# deployment/helm/enterprise-app/values.yaml
replicaCount: 3

image:
  repository: registry.example.com/enterprise-app
  pullPolicy: IfNotPresent
  tag: "1.0.0"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: api.enterprise.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: enterprise-tls
      hosts:
        - api.enterprise.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

#### 部署 Helm Chart

```bash
# 安装
helm install enterprise-app ./deployment/helm/enterprise-app \
  --namespace enterprise-app \
  --create-namespace

# 升级
helm upgrade enterprise-app ./deployment/helm/enterprise-app \
  --namespace enterprise-app

# 回滚
helm rollback enterprise-app 1 -n enterprise-app

# 卸载
helm uninstall enterprise-app -n enterprise-app
```

## CI/CD 流程

### GitLab CI/CD

创建 `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - test
  - package
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"
  DOCKER_REGISTRY: "registry.example.com"

cache:
  paths:
    - .m2/repository

build:
  stage: build
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn clean compile

test:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn test
    - mvn verify -P integration-tests
  artifacts:
    reports:
      junit: target/surefire-reports/TEST-*.xml

package:
  stage: package
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn package -DskipTests
    - mvn jib:build
  only:
    - main
    - develop

deploy-dev:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl apply -f deployment/kubernetes/dev/
  environment:
    name: development
  only:
    - develop

deploy-prod:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - helm upgrade --install enterprise-app ./deployment/helm/enterprise-app
  environment:
    name: production
  when: manual
  only:
    - main
```

### GitHub Actions

参考项目中的 `.github/workflows/ci-cd.yml`

## 部署策略

### 1. 滚动更新 (Rolling Update)

默认的 Kubernetes 部署策略：

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### 2. 蓝绿部署 (Blue-Green)

```bash
# 部署新版本（Green）
kubectl apply -f deployment/kubernetes/green/

# 切换流量
kubectl patch service user-service -p '{"spec":{"selector":{"version":"green"}}}'

# 验证后删除旧版本（Blue）
kubectl delete -f deployment/kubernetes/blue/
```

### 3. 金丝雀发布 (Canary)

使用 Istio 或 Flagger：

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: user-service
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  progressDeadlineSeconds: 60
  service:
    port: 8080
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
```

## 监控部署

### 部署 Prometheus Stack

```bash
# 添加 Prometheus Community Helm Chart
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装 kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin
```

### 部署 Loki

```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true
```

### 部署 Tempo

```bash
helm install tempo grafana/tempo \
  --namespace monitoring
```

### 访问监控服务

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# 浏览器访问
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090
```

## 扩缩容

### 手动扩缩容

```bash
# 扩容到 5 个副本
kubectl scale deployment user-service --replicas=5 -n enterprise-app

# 验证
kubectl get pods -n enterprise-app
```

### 自动扩缩容 (HPA)

HPA 配置已包含在部署文件中，基于 CPU 和内存使用率自动调整：

```bash
# 查看 HPA 状态
kubectl get hpa -n enterprise-app

# 详细信息
kubectl describe hpa user-service-hpa -n enterprise-app
```

### 集群自动扩缩容

在云环境中配置 Cluster Autoscaler：

```bash
# AWS EKS 示例
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

## 备份与恢复

### 数据库备份

```bash
# PostgreSQL 备份
kubectl exec -n enterprise-app postgresql-0 -- \
  pg_dump -U enterprise enterprise_db > backup.sql

# 恢复
kubectl exec -i -n enterprise-app postgresql-0 -- \
  psql -U enterprise enterprise_db < backup.sql
```

### Velero 备份整个集群

```bash
# 安装 Velero
velero install \
  --provider aws \
  --bucket velero-backups \
  --secret-file ./credentials-velero

# 创建备份
velero backup create enterprise-backup \
  --include-namespaces enterprise-app

# 恢复
velero restore create --from-backup enterprise-backup
```

## 故障排查

### 查看日志

```bash
# 实时日志
kubectl logs -f deployment/user-service -n enterprise-app

# 多个 Pod 的日志
kubectl logs -l app=user-service -n enterprise-app --tail=100

# 容器日志
kubectl logs <pod-name> -c <container-name> -n enterprise-app
```

### 进入容器

```bash
kubectl exec -it <pod-name> -n enterprise-app -- /bin/sh
```

### 查看事件

```bash
kubectl get events -n enterprise-app --sort-by='.lastTimestamp'
```

### 常见问题

#### Pod 无法启动

```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n enterprise-app

# 常见原因：
# 1. 镜像拉取失败 - 检查镜像仓库认证
# 2. 资源不足 - 调整 requests/limits
# 3. ConfigMap/Secret 不存在 - 检查依赖资源
```

#### 服务无法访问

```bash
# 检查 Service
kubectl get svc -n enterprise-app

# 检查 Endpoints
kubectl get endpoints -n enterprise-app

# 测试网络连接
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://user-service:8080/actuator/health
```

## 安全加固

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-gateway-to-services
  namespace: enterprise-app
spec:
  podSelector:
    matchLabels:
      app: user-service
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: gateway-service
    ports:
    - protocol: TCP
      port: 8080
```

### Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: enterprise-app
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: enterprise-app-role
  namespace: enterprise-app
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
```

## 性能优化

### JVM 参数调优

```yaml
env:
- name: JAVA_OPTS
  value: >-
    -Xms512m
    -Xmx1024m
    -XX:+UseZGC
    -XX:MaxGCPauseMillis=200
    -XX:+AlwaysPreTouch
    -XX:+DisableExplicitGC
```

### 资源请求优化

根据实际监控数据调整：

```yaml
resources:
  requests:
    memory: "512Mi"  # 实际使用量 + 20%
    cpu: "250m"      # 平均使用量
  limits:
    memory: "1Gi"    # 峰值使用量 + 50%
    cpu: "1000m"     # 峰值使用量
```

## 成本优化

1. **使用 Spot/Preemptible 实例** - 非关键工作负载
2. **资源配额** - 限制命名空间资源使用
3. **自动扩缩容** - 根据负载动态调整
4. **合理的副本数** - 避免过度配置
5. **使用 CDN** - 减少出口流量

## 下一步

- 查看 [监控告警配置](monitoring-guide.md)
- 了解 [灾难恢复计划](disaster-recovery.md)
- 阅读 [性能调优指南](performance-tuning.md)
