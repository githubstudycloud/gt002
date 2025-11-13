#!/bin/bash

###############################################################################
# Spring Boot项目构建脚本
# 用途: 编译打包Spring Boot应用
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$PROJECT_ROOT"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Spring Boot项目构建${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查Java环境
echo -e "${YELLOW}检查Java环境...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}错误: 未找到Java,请先安装JDK 17或更高版本${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo -e "${GREEN}Java版本: $JAVA_VERSION${NC}"

# 检查Maven环境
echo -e "${YELLOW}检查Maven环境...${NC}"
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}错误: 未找到Maven,请先安装Maven${NC}"
    exit 1
fi

MVN_VERSION=$(mvn -version | grep "Apache Maven" | awk '{print $3}')
echo -e "${GREEN}Maven版本: $MVN_VERSION${NC}"

# 清理并编译
echo -e "${YELLOW}开始清理并编译项目...${NC}"
mvn clean install -DskipTests

if [ $? -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}构建成功!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}构建失败!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi

# 显示构建产物
echo -e "${YELLOW}构建产物:${NC}"
find . -name "*.jar" -type f ! -path "*/target/original-*" | grep -v ".m2"

echo -e "${GREEN}构建完成!${NC}"
