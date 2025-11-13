#!/bin/bash
# Docker 镜像加载脚本
# 用于在内网服务器上合并分卷并加载镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Docker 镜像加载${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 配置
EXPORT_DIR="./images"

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

# 检查导出目录是否存在
if [ ! -d "${EXPORT_DIR}" ]; then
    echo -e "${RED}错误: 镜像目录 ${EXPORT_DIR} 不存在${NC}"
    exit 1
fi

cd ${EXPORT_DIR}

echo -e "${YELLOW}步骤 1/4: 验证文件完整性...${NC}"
if [ -f "checksums.txt" ]; then
    if sha256sum -c checksums.txt 2>/dev/null || shasum -a 256 -c checksums.txt 2>/dev/null; then
        echo -e "${GREEN}✓ 文件完整性验证通过${NC}"
    else
        echo -e "${RED}✗ 文件完整性验证失败${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ 未找到校验文件，跳过验证${NC}"
fi

echo ""
echo -e "${YELLOW}步骤 2/4: 合并分卷文件...${NC}"

# 合并 Claude Relay Service 镜像
if ls claude-relay-service.tar.gz.part-* 1> /dev/null 2>&1; then
    echo "  合并 claude-relay-service.tar.gz..."
    cat claude-relay-service.tar.gz.part-* > claude-relay-service.tar.gz

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ 合并成功${NC}"
        rm claude-relay-service.tar.gz.part-*
    else
        echo -e "${RED}  ✗ 合并失败${NC}"
        exit 1
    fi
else
    echo "  claude-relay-service.tar.gz 无需合并"
fi

# 合并 Redis 镜像
if ls redis.tar.gz.part-* 1> /dev/null 2>&1; then
    echo "  合并 redis.tar.gz..."
    cat redis.tar.gz.part-* > redis.tar.gz

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ 合并成功${NC}"
        rm redis.tar.gz.part-*
    else
        echo -e "${RED}  ✗ 合并失败${NC}"
        exit 1
    fi
else
    echo "  redis.tar.gz 无需合并"
fi

echo ""
echo -e "${YELLOW}步骤 3/4: 加载 Claude Relay Service 镜像...${NC}"
if [ -f "claude-relay-service.tar.gz" ]; then
    gunzip -c claude-relay-service.tar.gz | docker load

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Claude Relay Service 镜像加载成功${NC}"
    else
        echo -e "${RED}✗ 镜像加载失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}错误: 找不到 claude-relay-service.tar.gz${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 4/4: 加载 Redis 镜像...${NC}"
if [ -f "redis.tar.gz" ]; then
    gunzip -c redis.tar.gz | docker load

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Redis 镜像加载成功${NC}"
    else
        echo -e "${RED}✗ Redis 镜像加载失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}错误: 找不到 redis.tar.gz${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${YELLOW}验证已加载的镜像:${NC}"
docker images | grep -E "(claude-relay-service|redis)" | head -5

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}镜像加载完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "下一步操作:"
echo "  1. 复制 .env.example 为 .env"
echo "  2. 编辑 .env 文件，配置必要参数"
echo "  3. 运行 ./init-env.sh 初始化环境"
echo "  4. 运行 ./deploy.sh 启动服务"
echo ""
