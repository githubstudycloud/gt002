#!/bin/bash
# Docker 镜像导出和分卷脚本
# 将镜像导出并分割成小文件，适合 Git 上传（每个文件 < 50MB）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Docker 镜像导出和分卷${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 配置
IMAGE_NAME="claude-relay-service"
IMAGE_TAG="latest"
REDIS_IMAGE="redis:7-alpine"
EXPORT_DIR="./images"
CHUNK_SIZE="45M"  # 每个分卷大小 45MB，确保小于 Git 的 50MB 限制

# 创建导出目录
mkdir -p ${EXPORT_DIR}

echo -e "${YELLOW}步骤 1/4: 导出 Claude Relay Service 镜像...${NC}"
docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > ${EXPORT_DIR}/${IMAGE_NAME}.tar.gz

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像导出成功${NC}"
    IMAGE_SIZE=$(du -h ${EXPORT_DIR}/${IMAGE_NAME}.tar.gz | cut -f1)
    echo "  文件大小: ${IMAGE_SIZE}"
else
    echo -e "${RED}✗ 镜像导出失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2/4: 导出 Redis 镜像...${NC}"
docker save ${REDIS_IMAGE} | gzip > ${EXPORT_DIR}/redis.tar.gz

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Redis 镜像导出成功${NC}"
    REDIS_SIZE=$(du -h ${EXPORT_DIR}/redis.tar.gz | cut -f1)
    echo "  文件大小: ${REDIS_SIZE}"
else
    echo -e "${RED}✗ Redis 镜像导出失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3/4: 分割镜像文件...${NC}"

# 分割 Claude Relay Service 镜像
cd ${EXPORT_DIR}
if [ -f "${IMAGE_NAME}.tar.gz" ]; then
    FILE_SIZE=$(stat -f%z "${IMAGE_NAME}.tar.gz" 2>/dev/null || stat -c%s "${IMAGE_NAME}.tar.gz" 2>/dev/null)
    MAX_SIZE=$((50 * 1024 * 1024))  # 50MB

    if [ ${FILE_SIZE} -gt ${MAX_SIZE} ]; then
        echo "  分割 ${IMAGE_NAME}.tar.gz (大小: $(du -h ${IMAGE_NAME}.tar.gz | cut -f1))..."
        split -b ${CHUNK_SIZE} ${IMAGE_NAME}.tar.gz ${IMAGE_NAME}.tar.gz.part-

        if [ $? -eq 0 ]; then
            rm ${IMAGE_NAME}.tar.gz
            echo -e "${GREEN}  ✓ 分割成功${NC}"
            ls -lh ${IMAGE_NAME}.tar.gz.part-* | awk '{print "    - " $9 " (" $5 ")"}'
        else
            echo -e "${RED}  ✗ 分割失败${NC}"
            exit 1
        fi
    else
        echo "  ${IMAGE_NAME}.tar.gz 无需分割（小于 50MB）"
    fi
fi

# 分割 Redis 镜像
if [ -f "redis.tar.gz" ]; then
    FILE_SIZE=$(stat -f%z "redis.tar.gz" 2>/dev/null || stat -c%s "redis.tar.gz" 2>/dev/null)
    MAX_SIZE=$((50 * 1024 * 1024))

    if [ ${FILE_SIZE} -gt ${MAX_SIZE} ]; then
        echo "  分割 redis.tar.gz (大小: $(du -h redis.tar.gz | cut -f1))..."
        split -b ${CHUNK_SIZE} redis.tar.gz redis.tar.gz.part-

        if [ $? -eq 0 ]; then
            rm redis.tar.gz
            echo -e "${GREEN}  ✓ 分割成功${NC}"
            ls -lh redis.tar.gz.part-* | awk '{print "    - " $9 " (" $5 ")"}'
        else
            echo -e "${RED}  ✗ 分割失败${NC}"
            exit 1
        fi
    else
        echo "  redis.tar.gz 无需分割（小于 50MB）"
    fi
fi

cd ..

echo ""
echo -e "${YELLOW}步骤 4/4: 生成校验文件...${NC}"
cd ${EXPORT_DIR}
sha256sum * > checksums.txt 2>/dev/null || shasum -a 256 * > checksums.txt
echo -e "${GREEN}✓ 校验文件已生成${NC}"
cd ..

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}导出完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "导出文件位置: ${EXPORT_DIR}/"
echo ""
echo "文件列表:"
ls -lh ${EXPORT_DIR}/ | tail -n +2 | awk '{print "  " $9 " - " $5}'
echo ""
echo "下一步操作:"
echo "  1. 将 ${EXPORT_DIR} 目录提交到 Git"
echo "  2. 在内网服务器克隆仓库"
echo "  3. 运行 ./load-images.sh 加载镜像"
echo ""
