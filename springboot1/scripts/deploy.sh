#!/bin/bash

###############################################################################
# Spring Boot项目部署脚本
# 用途: 部署应用到不同环境
# 用法: ./deploy.sh [dev|test|staging|prod]
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_NAME="springboot1"
DOCKER_REGISTRY="registry.example.com"
NAMESPACE="springboot1"

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请指定部署环境 [dev|test|staging|prod]${NC}"
    echo -e "${YELLOW}用法: $0 [dev|test|staging|prod]${NC}"
    exit 1
fi

ENV=$1

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署到 ${ENV} 环境${NC}"
echo -e "${GREEN}========================================${NC}"

# 环境配置
case $ENV in
    dev)
        REPLICAS=1
        RESOURCES_LIMITS_CPU="1000m"
        RESOURCES_LIMITS_MEMORY="1Gi"
        ;;
    test)
        REPLICAS=2
        RESOURCES_LIMITS_CPU="2000m"
        RESOURCES_LIMITS_MEMORY="2Gi"
        ;;
    staging)
        REPLICAS=3
        RESOURCES_LIMITS_CPU="2000m"
        RESOURCES_LIMITS_MEMORY="2Gi"
        ;;
    prod)
        REPLICAS=5
        RESOURCES_LIMITS_CPU="4000m"
        RESOURCES_LIMITS_MEMORY="4Gi"
        ;;
    *)
        echo -e "${RED}错误: 不支持的环境 '$ENV'${NC}"
        exit 1
        ;;
esac

# 构建Docker镜像
echo -e "${YELLOW}步骤1: 构建Docker镜像...${NC}"
cd "$PROJECT_ROOT"

# 获取版本号
VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
IMAGE_TAG="${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}-${ENV}"
IMAGE_LATEST="${DOCKER_REGISTRY}/${APP_NAME}:latest-${ENV}"

echo -e "${BLUE}镜像标签: ${IMAGE_TAG}${NC}"

# 构建镜像
docker build -t "${IMAGE_TAG}" -t "${IMAGE_LATEST}" \
    --build-arg SPRING_PROFILES_ACTIVE="${ENV}" \
    -f docker/Dockerfile .

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker镜像构建失败!${NC}"
    exit 1
fi

echo -e "${GREEN}Docker镜像构建成功!${NC}"

# 推送镜像到仓库
echo -e "${YELLOW}步骤2: 推送镜像到仓库...${NC}"
docker push "${IMAGE_TAG}"
docker push "${IMAGE_LATEST}"

if [ $? -ne 0 ]; then
    echo -e "${RED}镜像推送失败!${NC}"
    exit 1
fi

echo -e "${GREEN}镜像推送成功!${NC}"

# 部署到Kubernetes
echo -e "${YELLOW}步骤3: 部署到Kubernetes...${NC}"

# 检查kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}错误: 未找到kubectl命令${NC}"
    exit 1
fi

# 创建命名空间(如果不存在)
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# 应用配置
cd "$PROJECT_ROOT/kubernetes/overlays/${ENV}"

if [ ! -d "$PROJECT_ROOT/kubernetes/overlays/${ENV}" ]; then
    echo -e "${YELLOW}警告: 未找到环境配置目录,使用基础配置${NC}"
    cd "$PROJECT_ROOT/kubernetes/base"
fi

# 使用kustomize部署
if command -v kustomize &> /dev/null; then
    echo -e "${BLUE}使用kustomize部署...${NC}"
    kustomize edit set image app=${IMAGE_TAG}
    kustomize build . | kubectl apply -n "${NAMESPACE}" -f -
else
    echo -e "${BLUE}使用kubectl部署...${NC}"
    kubectl apply -n "${NAMESPACE}" -f "$PROJECT_ROOT/kubernetes/base/"
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Kubernetes部署失败!${NC}"
    exit 1
fi

echo -e "${GREEN}Kubernetes部署成功!${NC}"

# 等待部署完成
echo -e "${YELLOW}步骤4: 等待部署就绪...${NC}"
kubectl rollout status deployment/${APP_NAME} -n "${NAMESPACE}" --timeout=300s

if [ $? -ne 0 ]; then
    echo -e "${RED}部署超时或失败!${NC}"
    echo -e "${YELLOW}查看Pod状态:${NC}"
    kubectl get pods -n "${NAMESPACE}" -l app=${APP_NAME}
    exit 1
fi

# 显示部署信息
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署成功完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}环境: ${ENV}${NC}"
echo -e "${BLUE}版本: ${VERSION}${NC}"
echo -e "${BLUE}副本数: ${REPLICAS}${NC}"
echo -e "${BLUE}命名空间: ${NAMESPACE}${NC}"
echo ""
echo -e "${YELLOW}查看Pod状态:${NC}"
kubectl get pods -n "${NAMESPACE}" -l app=${APP_NAME}
echo ""
echo -e "${YELLOW}查看服务:${NC}"
kubectl get svc -n "${NAMESPACE}"
echo ""
echo -e "${YELLOW}查看日志:${NC}"
echo "kubectl logs -f deployment/${APP_NAME} -n ${NAMESPACE}"
echo ""
echo -e "${GREEN}部署完成!${NC}"
