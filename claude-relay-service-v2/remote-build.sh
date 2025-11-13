#!/bin/bash
# 远程服务器构建和导出脚本
# 用法: ./remote-build.sh <服务器地址> <用户名>

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查参数
if [ $# -lt 2 ]; then
    echo -e "${RED}用法: $0 <服务器地址> <用户名>${NC}"
    echo "示例: $0 192.168.1.100 ubuntu"
    exit 1
fi

SERVER=$1
USER=$2
REMOTE_DIR="/tmp/claude-relay-build"
LOCAL_PROJECT="claude-relay-offline-deploy"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}远程构建 Docker 镜像${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "服务器: $SERVER"
echo "用户: $USER"
echo "远程目录: $REMOTE_DIR"
echo ""

# 步骤 1: 上传项目到远程服务器
echo -e "${YELLOW}步骤 1/5: 上传项目到远程服务器...${NC}"
ssh ${USER}@${SERVER} "mkdir -p ${REMOTE_DIR}"
rsync -avz --progress ${LOCAL_PROJECT}/ ${USER}@${SERVER}:${REMOTE_DIR}/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 项目上传成功${NC}"
else
    echo -e "${RED}✗ 项目上传失败${NC}"
    exit 1
fi

# 步骤 2: 在远程服务器检查 Docker
echo ""
echo -e "${YELLOW}步骤 2/5: 检查远程服务器 Docker 环境...${NC}"
ssh ${USER}@${SERVER} "docker --version && docker-compose --version"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker 环境检查通过${NC}"
else
    echo -e "${RED}✗ 远程服务器未安装 Docker${NC}"
    exit 1
fi

# 步骤 3: 构建镜像
echo ""
echo -e "${YELLOW}步骤 3/5: 在远程服务器构建 Docker 镜像...${NC}"
ssh ${USER}@${SERVER} "cd ${REMOTE_DIR} && chmod +x *.sh && ./build.sh"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像构建成功${NC}"
else
    echo -e "${RED}✗ 镜像构建失败${NC}"
    exit 1
fi

# 步骤 4: 导出并分卷镜像
echo ""
echo -e "${YELLOW}步骤 4/5: 导出并分卷镜像...${NC}"
ssh ${USER}@${SERVER} "cd ${REMOTE_DIR} && ./export-images.sh"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像导出成功${NC}"
else
    echo -e "${RED}✗ 镜像导出失败${NC}"
    exit 1
fi

# 步骤 5: 下载镜像文件到本地
echo ""
echo -e "${YELLOW}步骤 5/5: 下载镜像文件到本地...${NC}"
mkdir -p ${LOCAL_PROJECT}/images
rsync -avz --progress ${USER}@${SERVER}:${REMOTE_DIR}/images/ ${LOCAL_PROJECT}/images/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像下载成功${NC}"
else
    echo -e "${RED}✗ 镜像下载失败${NC}"
    exit 1
fi

# 显示结果
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}构建和下载完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "镜像文件位置: ${LOCAL_PROJECT}/images/"
echo ""
echo "文件列表:"
ls -lh ${LOCAL_PROJECT}/images/ | tail -n +2 | awk '{print "  " $9 " - " $5}'
echo ""
echo "下一步操作:"
echo "  1. 验证镜像: cd ${LOCAL_PROJECT} && sha256sum -c images/checksums.txt"
echo "  2. 提交到 Git: git add images/ && git commit -m 'Add Docker images'"
echo "  3. 推送: git push"
echo ""

# 可选: 清理远程服务器
read -p "是否清理远程服务器上的构建文件? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}清理远程服务器...${NC}"
    ssh ${USER}@${SERVER} "rm -rf ${REMOTE_DIR}"
    echo -e "${GREEN}✓ 清理完成${NC}"
fi
