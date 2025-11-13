.PHONY: help build clean test package deploy-docker deploy-k8s monitor logs

# 默认目标
.DEFAULT_GOAL := help

# 变量定义
PROJECT_NAME = springboot2-enterprise
VERSION = 1.0.0-SNAPSHOT
IMAGE_PREFIX = enterprise
NAMESPACE = enterprise

help: ## 显示帮助信息
	@echo "Spring Boot 2 企业级项目管理命令"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

clean: ## 清理编译文件
	@echo "==> 清理编译文件..."
	mvn clean

build: ## 编译项目
	@echo "==> 编译项目..."
	mvn clean compile

test: ## 运行测试
	@echo "==> 运行测试..."
	mvn test

package: ## 打包项目
	@echo "==> 打包项目..."
	mvn clean package -DskipTests

install: ## 安装到本地仓库
	@echo "==> 安装到本地仓库..."
	mvn clean install -DskipTests

# Docker 相关命令
docker-build-user: ## 构建用户服务 Docker 镜像
	@echo "==> 构建用户服务 Docker 镜像..."
	docker build -t $(IMAGE_PREFIX)/user-service:$(VERSION) -f enterprise-service-user/Dockerfile .

docker-push-user: ## 推送用户服务镜像
	@echo "==> 推送用户服务镜像..."
	docker push $(IMAGE_PREFIX)/user-service:$(VERSION)

docker-compose-up: ## 启动 Docker Compose 环境
	@echo "==> 启动 Docker Compose 环境..."
	docker-compose up -d

docker-compose-down: ## 停止 Docker Compose 环境
	@echo "==> 停止 Docker Compose 环境..."
	docker-compose down

docker-compose-logs: ## 查看 Docker Compose 日志
	@echo "==> 查看 Docker Compose 日志..."
	docker-compose logs -f

docker-compose-ps: ## 查看 Docker Compose 服务状态
	@echo "==> 查看 Docker Compose 服务状态..."
	docker-compose ps

# Kubernetes 相关命令
k8s-create-ns: ## 创建 K8s 命名空间
	@echo "==> 创建 K8s 命名空间..."
	kubectl apply -f k8s/namespace.yaml

k8s-create-config: ## 创建 K8s 配置
	@echo "==> 创建 K8s 配置..."
	kubectl apply -f k8s/configmap.yaml

k8s-deploy-user: ## 部署用户服务到 K8s
	@echo "==> 部署用户服务到 K8s..."
	kubectl apply -f k8s/user-service/deployment.yaml

k8s-deploy-all: k8s-create-ns k8s-create-config k8s-deploy-user ## 部署所有服务到 K8s
	@echo "==> 部署完成！"

k8s-delete: ## 删除 K8s 部署
	@echo "==> 删除 K8s 部署..."
	kubectl delete namespace $(NAMESPACE)

k8s-pods: ## 查看 K8s Pods
	@echo "==> 查看 K8s Pods..."
	kubectl get pods -n $(NAMESPACE)

k8s-svc: ## 查看 K8s Services
	@echo "==> 查看 K8s Services..."
	kubectl get svc -n $(NAMESPACE)

k8s-logs: ## 查看 K8s 日志
	@echo "==> 查看 K8s 日志（需要指定 POD_NAME）..."
	@read -p "请输入 Pod 名称: " pod; kubectl logs -f $$pod -n $(NAMESPACE)

k8s-describe: ## 查看 K8s Pod 详情
	@echo "==> 查看 K8s Pod 详情（需要指定 POD_NAME）..."
	@read -p "请输入 Pod 名称: " pod; kubectl describe pod $$pod -n $(NAMESPACE)

k8s-exec: ## 进入 K8s Pod
	@echo "==> 进入 K8s Pod（需要指定 POD_NAME）..."
	@read -p "请输入 Pod 名称: " pod; kubectl exec -it $$pod -n $(NAMESPACE) -- /bin/sh

k8s-scale: ## 扩缩容
	@echo "==> 扩缩容（需要指定 DEPLOYMENT 和 REPLICAS）..."
	@read -p "请输入 Deployment 名称: " deployment; \
	read -p "请输入副本数: " replicas; \
	kubectl scale deployment $$deployment --replicas=$$replicas -n $(NAMESPACE)

# 监控相关
monitor-prometheus: ## 打开 Prometheus
	@echo "==> 打开 Prometheus: http://localhost:9090"
	@open http://localhost:9090 || xdg-open http://localhost:9090 || start http://localhost:9090

monitor-grafana: ## 打开 Grafana
	@echo "==> 打开 Grafana: http://localhost:3000"
	@open http://localhost:3000 || xdg-open http://localhost:3000 || start http://localhost:3000

monitor-kibana: ## 打开 Kibana
	@echo "==> 打开 Kibana: http://localhost:5601"
	@open http://localhost:5601 || xdg-open http://localhost:5601 || start http://localhost:5601

monitor-nacos: ## 打开 Nacos
	@echo "==> 打开 Nacos: http://localhost:8848/nacos"
	@open http://localhost:8848/nacos || xdg-open http://localhost:8848/nacos || start http://localhost:8848/nacos

monitor-sentinel: ## 打开 Sentinel
	@echo "==> 打开 Sentinel: http://localhost:8858"
	@open http://localhost:8858 || xdg-open http://localhost:8858 || start http://localhost:8858

monitor-zipkin: ## 打开 Zipkin
	@echo "==> 打开 Zipkin: http://localhost:9411"
	@open http://localhost:9411 || xdg-open http://localhost:9411 || start http://localhost:9411

# 本地开发
dev-start: ## 启动本地开发环境
	@echo "==> 启动本地开发环境..."
	docker-compose up -d mysql redis nacos sentinel

dev-stop: ## 停止本地开发环境
	@echo "==> 停止本地开发环境..."
	docker-compose stop mysql redis nacos sentinel

dev-restart: ## 重启本地开发环境
	@echo "==> 重启本地开发环境..."
	docker-compose restart mysql redis nacos sentinel

# 完整部署流程
deploy-full: package docker-build-user docker-compose-up ## 完整部署流程（打包+构建镜像+启动）
	@echo "==> 部署完成！"
	@echo "==> 用户服务: http://localhost:8081"
	@echo "==> Nacos: http://localhost:8848/nacos"
	@echo "==> Grafana: http://localhost:3000"
