#!/bin/bash
# Claude Relay Service 镜像构建脚本
# 用于在有外网环境的机器上构建 Docker 镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Claude Relay Service 镜像构建${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

# 检查 Docker 服务是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker 服务未运行${NC}"
    exit 1
fi

# 设置镜像名称和标签
IMAGE_NAME="claude-relay-service"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${YELLOW}步骤 1/4: 构建 Claude Relay Service 镜像...${NC}"
docker build -t ${FULL_IMAGE_NAME} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像构建成功: ${FULL_IMAGE_NAME}${NC}"
else
    echo -e "${RED}✗ 镜像构建失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2/4: 拉取 Redis 镜像...${NC}"
docker pull redis:7-alpine

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Redis 镜像拉取成功${NC}"
else
    echo -e "${RED}✗ Redis 镜像拉取失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3/4: 验证镜像...${NC}"
docker images | grep -E "(${IMAGE_NAME}|redis)"

echo ""
echo -e "${YELLOW}步骤 4/4: 清理构建缓存...${NC}"
docker builder prune -f

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "镜像信息:"
echo "  - ${FULL_IMAGE_NAME}"
echo "  - redis:7-alpine"
echo ""
echo "下一步操作:"
echo "  1. 运行 ./export-images.sh 导出镜像"
echo "  2. 将镜像文件传输到内网服务器"
echo "  3. 在内网服务器上运行 ./load-images.sh 加载镜像"
echo ""
