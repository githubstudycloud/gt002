# 部署指南

## 目录
- [环境准备](#环境准备)
- [本地开发环境](#本地开发环境)
- [容器化部署](#容器化部署)
- [Kubernetes 集群部署](#kubernetes-集群部署)
- [CI/CD 流水线](#cicd-流水线)
- [监控配置](#监控配置)
- [故障排查](#故障排查)

## 环境准备

### 基础环境要求

#### 开发环境
- JDK 17+
- Maven 3.9+ 或 Gradle 8+
- Docker 24+
- Docker Compose 2.20+
- IDE（IntelliJ IDEA 2023+）

#### 生产环境
- Kubernetes 1.27+
- Helm 3.12+
- kubectl
- Harbor 或其他镜像仓库
- 至少 3 个 Worker 节点（生产环境建议 5+）

### 中间件版本
- PostgreSQL 16
- Redis 7
- Kafka 3.6
- Elasticsearch 8.12
- Nacos 2.3

## 本地开发环境

### 1. 启动基础设施

使用 Docker Compose 启动所有依赖的中间件：

```bash
cd infrastructure/docker
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]
```

启动后可访问：
- Nacos: http://localhost:8848/nacos (nacos/nacos)
- Grafana: http://localhost:3000 (admin/admin123)
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686
- Kibana: http://localhost:5601

### 2. 编译项目

```bash
# 编译所有模块
mvn clean package -DskipTests

# 编译指定模块
mvn clean package -pl gateway -am -DskipTests
```

### 3. 启动服务

#### 方式 1: IDE 启动（推荐开发时使用）

在 IntelliJ IDEA 中：
1. 右键 `Application.java`
2. 选择 "Run" 或 "Debug"
3. 配置 VM Options: `-Dspring.profiles.active=dev`

#### 方式 2: 命令行启动

```bash
# 启动网关
java -jar gateway/target/gateway-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev

# 启动认证服务
java -jar auth-service/target/auth-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev

# 启动用户服务
java -jar user-service/target/user-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev
```

### 4. 验证服务

```bash
# 健康检查
curl http://localhost:8080/actuator/health

# API 测试
curl http://localhost:8080/api/users

# 查看 API 文档
open http://localhost:8080/swagger-ui.html
```

## 容器化部署

### 1. 构建 Docker 镜像

#### 使用 Jib（推荐）

```bash
# 构建并推送到远程仓库
mvn compile jib:build

# 构建到本地 Docker
mvn compile jib:dockerBuild

# 构建指定服务
mvn compile jib:build -pl gateway
```

#### 使用 Dockerfile

```bash
# 构建镜像
docker build -t registry.example.com/gateway:1.0.0 ./gateway

# 推送镜像
docker push registry.example.com/gateway:1.0.0
```

### 2. 使用 Docker Compose 运行

```bash
# 启动所有服务
docker-compose -f docker-compose-app.yml up -d

# 查看日志
docker-compose -f docker-compose-app.yml logs -f

# 停止服务
docker-compose -f docker-compose-app.yml down
```

## Kubernetes 集群部署

### 1. 准备 Kubernetes 集群

#### 安装 kubectl

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### 配置 kubeconfig

```bash
# 设置 kubeconfig
export KUBECONFIG=/path/to/kubeconfig

# 验证连接
kubectl cluster-info
kubectl get nodes
```

### 2. 安装必要组件

#### Nginx Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

#### Cert-Manager（HTTPS 证书管理）

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
```

#### Metrics Server（监控指标）

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 3. 创建命名空间和配置

```bash
# 创建命名空间
kubectl apply -f infrastructure/kubernetes/namespace.yaml

# 创建 ConfigMap
kubectl create configmap app-config \
  --from-file=application.yml \
  -n springboot3-enterprise

# 创建 Secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=admin123 \
  -n springboot3-enterprise

# 创建 Docker Registry Secret
kubectl create secret docker-registry registry-secret \
  --docker-server=registry.example.com \
  --docker-username=admin \
  --docker-password=admin123 \
  -n springboot3-enterprise
```

### 4. 部署应用

#### 部署基础设施（数据库、缓存等）

```bash
# 部署 PostgreSQL
kubectl apply -f infrastructure/kubernetes/postgresql.yaml

# 部署 Redis
kubectl apply -f infrastructure/kubernetes/redis.yaml

# 部署 Nacos
kubectl apply -f infrastructure/kubernetes/nacos.yaml
```

#### 部署应用服务

```bash
# 部署网关
kubectl apply -f infrastructure/kubernetes/gateway-deployment.yaml

# 部署其他微服务
kubectl apply -f infrastructure/kubernetes/auth-service-deployment.yaml
kubectl apply -f infrastructure/kubernetes/user-service-deployment.yaml
kubectl apply -f infrastructure/kubernetes/order-service-deployment.yaml
kubectl apply -f infrastructure/kubernetes/product-service-deployment.yaml

# 配置 Ingress
kubectl apply -f infrastructure/kubernetes/ingress.yaml
```

#### 验证部署

```bash
# 查看 Pod 状态
kubectl get pods -n springboot3-enterprise

# 查看 Service
kubectl get svc -n springboot3-enterprise

# 查看 Deployment
kubectl get deployment -n springboot3-enterprise

# 查看详细信息
kubectl describe pod <pod-name> -n springboot3-enterprise

# 查看日志
kubectl logs -f <pod-name> -n springboot3-enterprise

# 进入容器
kubectl exec -it <pod-name> -n springboot3-enterprise -- /bin/sh
```

### 5. 配置自动扩缩容

HPA（Horizontal Pod Autoscaler）已在 deployment 文件中配置，可以手动调整：

```bash
# 查看 HPA 状态
kubectl get hpa -n springboot3-enterprise

# 手动扩容
kubectl scale deployment gateway --replicas=5 -n springboot3-enterprise

# 测试自动扩容
kubectl run -it --rm load-generator --image=busybox -- /bin/sh
while true; do wget -q -O- http://gateway.springboot3-enterprise.svc.cluster.local:8080; done
```

### 6. 滚动更新

```bash
# 更新镜像
kubectl set image deployment/gateway \
  gateway=registry.example.com/gateway:2.0.0 \
  -n springboot3-enterprise --record

# 查看滚动更新状态
kubectl rollout status deployment/gateway -n springboot3-enterprise

# 查看历史版本
kubectl rollout history deployment/gateway -n springboot3-enterprise

# 回滚到上一个版本
kubectl rollout undo deployment/gateway -n springboot3-enterprise

# 回滚到指定版本
kubectl rollout undo deployment/gateway --to-revision=2 -n springboot3-enterprise

# 暂停/恢复滚动更新
kubectl rollout pause deployment/gateway -n springboot3-enterprise
kubectl rollout resume deployment/gateway -n springboot3-enterprise
```

## CI/CD 流水线

### Jenkins 流水线

#### 1. 安装 Jenkins 插件
- Pipeline
- Docker Pipeline
- Kubernetes
- SonarQube Scanner
- JaCoCo
- Blue Ocean

#### 2. 配置凭证
在 Jenkins 中添加以下凭证：
- `docker-registry-credentials`: Docker 仓库认证
- `k8s-credentials`: Kubernetes 集群配置
- `sonarqube-token`: SonarQube Token
- `jenkins-dingtalk`: 钉钉机器人 Webhook

#### 3. 创建流水线任务
1. 新建 Pipeline 任务
2. 配置 Git 仓库
3. 指定 Jenkinsfile 路径: `infrastructure/ci-cd/Jenkinsfile`
4. 配置 Webhook 触发器

#### 4. 执行构建
```bash
# 手动触发构建
# 在 Jenkins UI 中点击 "Build with Parameters"

# Git 提交自动触发
git add .
git commit -m "Update feature"
git push origin develop
```

### GitLab CI/CD

#### 1. 配置 GitLab Runner
```bash
# 注册 Runner
gitlab-runner register \
  --url https://gitlab.example.com/ \
  --registration-token YOUR_TOKEN \
  --executor docker \
  --docker-image maven:3.9-eclipse-temurin-17
```

#### 2. 配置 CI/CD 变量
在 GitLab 项目设置中添加：
- `DOCKER_USERNAME`: Docker 仓库用户名
- `DOCKER_PASSWORD`: Docker 仓库密码
- `KUBE_CONFIG`: Kubernetes 配置（Base64 编码）
- `SONAR_TOKEN`: SonarQube Token

#### 3. 使用 .gitlab-ci.yml
将 `infrastructure/ci-cd/gitlab-ci.yml` 复制到项目根目录并重命名为 `.gitlab-ci.yml`

#### 4. 执行流水线
```bash
# 提交代码触发流水线
git add .
git commit -m "Trigger CI/CD"
git push origin main

# 创建标签触发生产部署
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## 监控配置

### 1. 部署 Prometheus

```bash
# 使用 Helm 安装 Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values infrastructure/monitoring/prometheus-values.yaml
```

### 2. 部署 Grafana

Grafana 通常包含在 kube-prometheus-stack 中，访问：

```bash
# 获取 Grafana 密码
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# 端口转发
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 访问 http://localhost:3000
```

导入仪表板：
- Spring Boot Dashboard: ID 12900
- JVM Dashboard: ID 4701
- Kubernetes Cluster Monitoring: ID 7249

### 3. 配置 Jaeger

```bash
# 使用 Helm 安装 Jaeger
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set provisionDataStore.cassandra=false \
  --set allInOne.enabled=true \
  --set storage.type=memory

# 访问 Jaeger UI
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
```

### 4. 配置告警

编辑 Prometheus AlertManager 配置：

```yaml
route:
  receiver: 'dingtalk'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h

receivers:
  - name: 'dingtalk'
    webhook_configs:
      - url: 'http://dingtalk-webhook:8060/dingtalk/webhook/send'
        send_resolved: true
```

## 故障排查

### 常见问题

#### 1. Pod 无法启动

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name> -n springboot3-enterprise

# 查看日志
kubectl logs <pod-name> -n springboot3-enterprise

# 查看上一个容器的日志（如果容器重启了）
kubectl logs <pod-name> --previous -n springboot3-enterprise
```

#### 2. 服务连接问题

```bash
# 测试服务连通性
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://gateway.springboot3-enterprise.svc.cluster.local:8080/actuator/health

# 查看 Service Endpoints
kubectl get endpoints -n springboot3-enterprise
```

#### 3. 数据库连接失败

```bash
# 检查数据库 Pod
kubectl get pod -n springboot3-enterprise | grep postgres

# 测试数据库连接
kubectl run -it --rm psql-client --image=postgres:16-alpine --restart=Never -- \
  psql -h postgres.springboot3-enterprise.svc.cluster.local -U admin -d enterprise_db
```

#### 4. 性能问题

```bash
# 查看资源使用情况
kubectl top pods -n springboot3-enterprise
kubectl top nodes

# 查看 HPA 状态
kubectl get hpa -n springboot3-enterprise

# 查看 Pod 详细指标
kubectl describe pod <pod-name> -n springboot3-enterprise | grep -A 5 "Limits\|Requests"
```

#### 5. 网络问题

```bash
# 检查网络策略
kubectl get networkpolicy -n springboot3-enterprise

# 测试 Pod 间通信
kubectl exec -it <pod-name> -n springboot3-enterprise -- ping <target-service>

# 查看 DNS 解析
kubectl exec -it <pod-name> -n springboot3-enterprise -- nslookup gateway.springboot3-enterprise.svc.cluster.local
```

### 日志收集

```bash
# 收集所有 Pod 日志
for pod in $(kubectl get pods -n springboot3-enterprise -o name); do
  kubectl logs $pod -n springboot3-enterprise > logs/${pod}.log
done

# 导出事件
kubectl get events -n springboot3-enterprise --sort-by='.lastTimestamp' > events.log
```

### 备份和恢复

#### 数据库备份

```bash
# PostgreSQL 备份
kubectl exec -it postgres-0 -n springboot3-enterprise -- \
  pg_dump -U admin enterprise_db > backup.sql

# 恢复
kubectl exec -i postgres-0 -n springboot3-enterprise -- \
  psql -U admin enterprise_db < backup.sql
```

#### Kubernetes 资源备份

```bash
# 导出所有资源
kubectl get all -n springboot3-enterprise -o yaml > backup.yaml

# 使用 Velero 备份
velero backup create springboot3-backup --include-namespaces springboot3-enterprise
```

## 最佳实践

1. **资源限制**: 始终为 Pod 设置 resources.requests 和 resources.limits
2. **健康检查**: 配置合适的 livenessProbe 和 readinessProbe
3. **滚动更新**: 使用 RollingUpdate 策略并设置合理的 maxSurge 和 maxUnavailable
4. **配置管理**: 使用 ConfigMap 和 Secret 管理配置，不要硬编码
5. **日志规范**: 统一日志格式，使用 JSON 格式便于解析
6. **监控告警**: 设置关键指标的告警规则
7. **安全加固**: 使用 NetworkPolicy 限制网络访问，定期更新镜像
8. **备份策略**: 定期备份数据库和重要配置

## 参考资料

- [Spring Boot 官方文档](https://spring.io/projects/spring-boot)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Docker 文档](https://docs.docker.com/)
- [Prometheus 文档](https://prometheus.io/docs/)
- [Jenkins 文档](https://www.jenkins.io/doc/)
