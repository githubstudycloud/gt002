#!/bin/bash
# 环境初始化脚本
# 生成密钥和初始化环境配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Claude Relay Service 环境初始化${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

ENV_FILE=".env"

# 检查 .env 文件是否存在
if [ -f "${ENV_FILE}" ]; then
    echo -e "${YELLOW}检测到现有 .env 文件${NC}"
    read -p "是否覆盖现有配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消操作"
        exit 0
    fi
    mv ${ENV_FILE} ${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}✓ 已备份原配置文件${NC}"
fi

# 生成密钥的函数
generate_key() {
    local length=$1
    # 尝试使用 openssl
    if command -v openssl &> /dev/null; then
        if [ "$length" == "32" ]; then
            openssl rand -hex 16
        else
            openssl rand -base64 $length | tr -d '\n=' | cut -c1-$length
        fi
    # 尝试使用 /dev/urandom
    elif [ -r /dev/urandom ]; then
        if [ "$length" == "32" ]; then
            head -c 16 /dev/urandom | xxd -p -c 16
        else
            head -c $length /dev/urandom | base64 | tr -d '\n=' | cut -c1-$length
        fi
    # 使用 bash RANDOM
    else
        local key=""
        for i in $(seq 1 $length); do
            key="${key}$(printf '%x' $((RANDOM % 16)))"
        done
        echo "$key" | cut -c1-$length
    fi
}

echo -e "${YELLOW}步骤 1/3: 生成安全密钥...${NC}"

# 生成 JWT Secret (至少 32 字符)
JWT_SECRET=$(generate_key 48)
echo -e "${GREEN}✓ JWT_SECRET 已生成${NC}"

# 生成 Encryption Key (必须是 32 字符)
ENCRYPTION_KEY=$(generate_key 32)
echo -e "${GREEN}✓ ENCRYPTION_KEY 已生成${NC}"

# 生成 Redis 密码 (可选)
REDIS_PASSWORD=$(generate_key 24)
echo -e "${GREEN}✓ REDIS_PASSWORD 已生成${NC}"

echo ""
echo -e "${YELLOW}步骤 2/3: 创建 .env 配置文件...${NC}"

# 从 .env.example 复制并替换
cp .env.example ${ENV_FILE}

# 替换密钥
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|JWT_SECRET=|JWT_SECRET=${JWT_SECRET}|g" ${ENV_FILE}
    sed -i '' "s|ENCRYPTION_KEY=|ENCRYPTION_KEY=${ENCRYPTION_KEY}|g" ${ENV_FILE}
    sed -i '' "s|REDIS_PASSWORD=|REDIS_PASSWORD=${REDIS_PASSWORD}|g" ${ENV_FILE}
else
    # Linux
    sed -i "s|JWT_SECRET=|JWT_SECRET=${JWT_SECRET}|g" ${ENV_FILE}
    sed -i "s|ENCRYPTION_KEY=|ENCRYPTION_KEY=${ENCRYPTION_KEY}|g" ${ENV_FILE}
    sed -i "s|REDIS_PASSWORD=|REDIS_PASSWORD=${REDIS_PASSWORD}|g" ${ENV_FILE}
fi

echo -e "${GREEN}✓ .env 文件已创建${NC}"

echo ""
echo -e "${YELLOW}步骤 3/3: 创建数据目录...${NC}"
mkdir -p data/logs
mkdir -p data/app
mkdir -p data/redis

echo -e "${GREEN}✓ 数据目录已创建${NC}"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}初始化完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "生成的密钥信息:"
echo "  JWT_SECRET: ${JWT_SECRET:0:10}... (已保存到 .env)"
echo "  ENCRYPTION_KEY: ${ENCRYPTION_KEY:0:10}... (已保存到 .env)"
echo "  REDIS_PASSWORD: ${REDIS_PASSWORD:0:10}... (已保存到 .env)"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "  1. 请妥善保管 .env 文件，不要提交到 Git"
echo "  2. 如果重新生成密钥，将无法访问旧的 Redis 数据"
echo "  3. 可以手动编辑 .env 文件自定义其他配置"
echo ""
echo "下一步操作:"
echo "  运行 ./deploy.sh 启动服务"
echo ""
