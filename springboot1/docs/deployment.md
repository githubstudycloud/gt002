# 部署指南

## 1. 环境准备

### 1.1 开发环境要求

**必需软件:**
- JDK 17+
- Maven 3.8+
- Docker 20.10+
- Docker Compose 2.0+
- Git 2.30+

**可选软件:**
- Kubernetes 1.25+ (生产环境)
- Helm 3.0+ (K8s包管理)
- kubectl 1.25+ (K8s命令行工具)

### 1.2 环境变量配置

```bash
# Java环境
export JAVA_HOME=/usr/lib/jvm/java-17
export PATH=$JAVA_HOME/bin:$PATH

# Maven配置
export MAVEN_HOME=/usr/local/maven
export PATH=$MAVEN_HOME/bin:$PATH
export MAVEN_OPTS="-Xms256m -Xmx512m"

# Docker配置
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

## 2. 本地开发环境部署

### 2.1 克隆代码

```bash
git clone https://github.com/your-org/springboot1.git
cd springboot1
```

### 2.2 启动基础设施

```bash
# 启动所有依赖服务
cd docker
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

**服务访问地址:**
- MySQL: localhost:3306
- Redis: localhost:6379
- RabbitMQ管理界面: http://localhost:15672 (admin/admin123)
- Nacos控制台: http://localhost:8848/nacos (nacos/nacos)
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin123)
- MinIO: http://localhost:9001 (admin/admin123456)

### 2.3 构建项目

```bash
# 回到项目根目录
cd ..

# 清理并编译
./scripts/build.sh

# 或使用Maven命令
mvn clean install -DskipTests
```

### 2.4 启动应用

**方式1: IDE启动 (推荐开发时使用)**
1. 导入项目到IDEA或Eclipse
2. 运行各个服务的Application主类
3. 配置active profile为dev

**方式2: 命令行启动**
```bash
# 启动网关服务
cd gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 启动认证服务
cd ../auth
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 启动业务服务
cd ../user/user-biz
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

**方式3: jar包启动**
```bash
# 构建jar包
mvn clean package -DskipTests

# 启动服务
java -jar -Dspring.profiles.active=dev gateway/target/gateway-1.0.0-SNAPSHOT.jar
```

## 3. Docker容器化部署

### 3.1 构建Docker镜像

```bash
# 构建所有服务镜像
./scripts/docker-build-all.sh

# 或单独构建某个服务
docker build -t springboot1/gateway:latest \
  --build-arg MODULE_NAME=gateway \
  -f docker/Dockerfile .
```

### 3.2 运行容器

```bash
# 启动单个服务
docker run -d \
  --name gateway \
  --network springboot1_springboot1-net \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=dev \
  springboot1/gateway:latest

# 使用docker-compose启动所有服务
docker-compose -f docker/docker-compose-app.yml up -d
```

### 3.3 容器管理

```bash
# 查看容器状态
docker ps

# 查看容器日志
docker logs -f gateway

# 进入容器
docker exec -it gateway sh

# 停止容器
docker stop gateway

# 删除容器
docker rm gateway
```

## 4. Kubernetes集群部署

### 4.1 准备Kubernetes集群

**本地测试环境 (minikube):**
```bash
# 安装minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 启动集群
minikube start --cpus=4 --memory=8192 --driver=docker

# 启用必要插件
minikube addons enable ingress
minikube addons enable metrics-server
```

**生产环境 (云服务):**
- 阿里云 ACK
- 腾讯云 TKE
- AWS EKS
- 自建K8s集群

### 4.2 部署应用到K8s

**方式1: 使用kubectl**
```bash
# 创建命名空间
kubectl create namespace springboot1

# 部署应用
kubectl apply -f kubernetes/base/ -n springboot1

# 查看部署状态
kubectl get pods -n springboot1
kubectl get svc -n springboot1
kubectl get ingress -n springboot1
```

**方式2: 使用Helm**
```bash
# 安装Helm Chart
helm install springboot1 kubernetes/helm/springboot1 \
  --namespace springboot1 \
  --create-namespace \
  --values kubernetes/helm/springboot1/values-prod.yaml

# 查看发布状态
helm list -n springboot1

# 升级应用
helm upgrade springboot1 kubernetes/helm/springboot1 \
  --namespace springboot1
```

**方式3: 使用部署脚本**
```bash
# 部署到开发环境
./scripts/deploy.sh dev

# 部署到测试环境
./scripts/deploy.sh test

# 部署到生产环境
./scripts/deploy.sh prod
```

### 4.3 配置Ingress

```bash
# 应用Ingress配置
kubectl apply -f kubernetes/base/ingress.yaml -n springboot1

# 获取Ingress地址
kubectl get ingress -n springboot1

# 配置域名解析
# 将域名指向Ingress LoadBalancer的外部IP
```

### 4.4 配置持久化存储

```bash
# 创建PVC
kubectl apply -f kubernetes/base/pvc.yaml -n springboot1

# 查看PVC状态
kubectl get pvc -n springboot1
```

### 4.5 配置ConfigMap和Secret

```bash
# 创建ConfigMap
kubectl create configmap app-config \
  --from-file=application.yml \
  -n springboot1

# 创建Secret
kubectl create secret generic app-secrets \
  --from-literal=db-password=your-password \
  --from-literal=redis-password=your-password \
  -n springboot1

# 查看配置
kubectl get configmap -n springboot1
kubectl get secret -n springboot1
```

## 5. CI/CD流水线配置

### 5.1 Jenkins Pipeline

```groovy
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        K8S_NAMESPACE = 'springboot1'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your-org/springboot1.git'
            }
        }

        stage('Build') {
            steps {
                sh './scripts/build.sh'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Docker Build') {
            steps {
                sh './scripts/docker-build-all.sh'
            }
        }

        stage('Push to Registry') {
            steps {
                sh 'docker push ${DOCKER_REGISTRY}/springboot1:${BUILD_NUMBER}'
            }
        }

        stage('Deploy to K8s') {
            steps {
                sh './scripts/deploy.sh prod'
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
```

### 5.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - docker
  - deploy

variables:
  DOCKER_REGISTRY: registry.example.com
  K8S_NAMESPACE: springboot1

build:
  stage: build
  script:
    - ./scripts/build.sh
  artifacts:
    paths:
      - "*/target/*.jar"
    expire_in: 1 day

test:
  stage: test
  script:
    - mvn test
  coverage: '/Total.*?([0-9]{1,3})%/'

docker:
  stage: docker
  script:
    - ./scripts/docker-build-all.sh
    - docker push $DOCKER_REGISTRY/springboot1:$CI_COMMIT_SHORT_SHA

deploy_prod:
  stage: deploy
  script:
    - ./scripts/deploy.sh prod
  only:
    - main
  when: manual
```

### 5.3 GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: maven

    - name: Build with Maven
      run: mvn clean install -DskipTests

    - name: Run tests
      run: mvn test

    - name: Build Docker images
      run: ./scripts/docker-build-all.sh

    - name: Deploy to Kubernetes
      if: github.ref == 'refs/heads/main'
      run: ./scripts/deploy.sh prod
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
```

## 6. 监控部署

### 6.1 部署Prometheus

```bash
# 使用Helm部署Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus/values.yaml
```

### 6.2 部署Grafana

```bash
# Grafana已包含在kube-prometheus-stack中
# 访问Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 导入Dashboard
# 访问 http://localhost:3000
# 导入monitoring/grafana/dashboards/下的JSON文件
```

### 6.3 部署ELK

```bash
# 使用Helm部署ELK
helm repo add elastic https://helm.elastic.co
helm repo update

# 部署Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --create-namespace

# 部署Kibana
helm install kibana elastic/kibana \
  --namespace logging

# 部署Filebeat
helm install filebeat elastic/filebeat \
  --namespace logging
```

## 7. 生产环境检查清单

### 7.1 部署前检查
- [ ] 代码审查完成
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 性能测试通过
- [ ] 安全扫描通过
- [ ] 配置文件检查
- [ ] 数据库迁移脚本准备
- [ ] 回滚方案准备

### 7.2 部署后检查
- [ ] 服务健康检查
- [ ] 日志输出正常
- [ ] 监控指标正常
- [ ] 告警配置生效
- [ ] 接口功能测试
- [ ] 性能指标达标
- [ ] 数据一致性验证

### 7.3 运维检查
- [ ] 备份策略执行
- [ ] 监控大盘查看
- [ ] 日志分析
- [ ] 容量评估
- [ ] 安全加固
- [ ] 文档更新

## 8. 故障排查

### 8.1 应用无法启动
```bash
# 查看Pod状态
kubectl describe pod <pod-name> -n springboot1

# 查看日志
kubectl logs <pod-name> -n springboot1

# 检查配置
kubectl get configmap -n springboot1
kubectl get secret -n springboot1
```

### 8.2 服务间调用失败
```bash
# 检查服务发现
kubectl get svc -n springboot1

# 检查网络策略
kubectl get networkpolicy -n springboot1

# 测试网络连通性
kubectl exec -it <pod-name> -n springboot1 -- curl http://service-name:port
```

### 8.3 性能问题
```bash
# 查看资源使用
kubectl top pods -n springboot1
kubectl top nodes

# 查看HPA状态
kubectl get hpa -n springboot1

# 分析JVM
kubectl exec -it <pod-name> -n springboot1 -- jmap -heap 1
```

## 9. 回滚操作

### 9.1 Kubernetes回滚
```bash
# 查看部署历史
kubectl rollout history deployment/springboot-app -n springboot1

# 回滚到上一版本
kubectl rollout undo deployment/springboot-app -n springboot1

# 回滚到指定版本
kubectl rollout undo deployment/springboot-app --to-revision=2 -n springboot1
```

### 9.2 Helm回滚
```bash
# 查看发布历史
helm history springboot1 -n springboot1

# 回滚到上一版本
helm rollback springboot1 -n springboot1

# 回滚到指定版本
helm rollback springboot1 2 -n springboot1
```

## 10. 性能调优

### 10.1 JVM参数优化
```bash
# 生产环境推荐配置
JAVA_OPTS="-Xms4g -Xmx4g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/app/logs/heapdump.hprof \
  -XX:+PrintGCDetails \
  -XX:+PrintGCDateStamps \
  -Xloggc:/app/logs/gc.log \
  -XX:+UseGCLogFileRotation \
  -XX:NumberOfGCLogFiles=10 \
  -XX:GCLogFileSize=10M"
```

### 10.2 资源配置优化
```yaml
# Kubernetes资源配置
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 4000m
    memory: 4Gi
```

### 10.3 数据库连接池优化
```yaml
spring:
  datasource:
    hikari:
      minimum-idle: 10
      maximum-pool-size: 50
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```
