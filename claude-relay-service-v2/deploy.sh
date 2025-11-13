#!/bin/bash
# Claude Relay Service 部署脚本
# 用于启动和管理服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示使用帮助
show_help() {
    echo "Claude Relay Service 部署管理脚本"
    echo ""
    echo "用法: ./deploy.sh [命令]"
    echo ""
    echo "命令:"
    echo "  start      启动服务 (默认)"
    echo "  stop       停止服务"
    echo "  restart    重启服务"
    echo "  status     查看服务状态"
    echo "  logs       查看服务日志"
    echo "  clean      清理并重启服务"
    echo "  help       显示此帮助信息"
    echo ""
}

# 检查 Docker 和 docker-compose
check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 服务未运行${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        echo -e "${RED}错误: docker-compose 未安装${NC}"
        exit 1
    fi

    # 使用 docker compose 或 docker-compose
    if docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        DOCKER_COMPOSE="docker-compose"
    fi
}

# 检查环境配置
check_env() {
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠ 未找到 .env 文件${NC}"
        echo ""
        read -p "是否运行 init-env.sh 初始化环境? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if [ -f "init-env.sh" ]; then
                chmod +x init-env.sh
                ./init-env.sh
            else
                echo -e "${RED}错误: 找不到 init-env.sh 脚本${NC}"
                exit 1
            fi
        else
            echo -e "${RED}错误: 需要 .env 文件才能启动服务${NC}"
            exit 1
        fi
    fi
}

# 启动服务
start_service() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}启动 Claude Relay Service${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""

    check_requirements
    check_env

    echo -e "${YELLOW}正在启动服务...${NC}"
    $DOCKER_COMPOSE up -d

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ 服务启动成功！${NC}"
        echo ""
        sleep 3
        show_status
        show_access_info
    else
        echo -e "${RED}✗ 服务启动失败${NC}"
        exit 1
    fi
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}正在停止服务...${NC}"
    check_requirements
    $DOCKER_COMPOSE down

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 服务已停止${NC}"
    else
        echo -e "${RED}✗ 停止服务失败${NC}"
        exit 1
    fi
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}正在重启服务...${NC}"
    check_requirements
    $DOCKER_COMPOSE restart

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 服务已重启${NC}"
        sleep 3
        show_status
    else
        echo -e "${RED}✗ 重启服务失败${NC}"
        exit 1
    fi
}

# 查看服务状态
show_status() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}服务状态${NC}"
    echo -e "${BLUE}======================================${NC}"
    check_requirements
    $DOCKER_COMPOSE ps
}

# 查看日志
show_logs() {
    echo -e "${BLUE}服务日志 (按 Ctrl+C 退出)${NC}"
    echo ""
    check_requirements
    $DOCKER_COMPOSE logs -f
}

# 清理并重启
clean_restart() {
    echo -e "${YELLOW}清理并重启服务...${NC}"
    echo -e "${RED}警告: 这将删除所有容器并重新创建${NC}"
    read -p "确认继续? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_requirements
        $DOCKER_COMPOSE down -v
        $DOCKER_COMPOSE up -d
        echo -e "${GREEN}✓ 服务已清理并重启${NC}"
        sleep 3
        show_status
    else
        echo "已取消操作"
    fi
}

# 显示访问信息
show_access_info() {
    # 获取端口
    PORT=$(grep "^PORT=" .env 2>/dev/null | cut -d'=' -f2)
    PORT=${PORT:-3000}

    # 获取绑定地址
    BIND_HOST=$(grep "^BIND_HOST=" .env 2>/dev/null | cut -d'=' -f2)
    BIND_HOST=${BIND_HOST:-0.0.0.0}

    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}访问信息${NC}"
    echo -e "${BLUE}======================================${NC}"

    # 获取本机 IP
    if command -v hostname &> /dev/null; then
        LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ -z "$LOCAL_IP" ]; then
            LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr eth0 2>/dev/null || echo "127.0.0.1")
        fi
    else
        LOCAL_IP="127.0.0.1"
    fi

    echo ""
    echo "管理界面访问地址:"
    if [ "$BIND_HOST" == "0.0.0.0" ] || [ "$BIND_HOST" == "" ]; then
        echo "  本地: http://localhost:${PORT}/web"
        echo "  局域网: http://${LOCAL_IP}:${PORT}/web"
    else
        echo "  http://${BIND_HOST}:${PORT}/web"
    fi

    echo ""
    echo "API 端点:"
    echo "  Claude API: http://${LOCAL_IP}:${PORT}/api"
    echo "  健康检查: http://${LOCAL_IP}:${PORT}/health"

    echo ""
    echo "首次登录:"
    echo "  管理员凭据保存在: ./data/app/init.json"
    echo "  查看凭据: cat ./data/app/init.json"

    echo ""
    echo "日志文件:"
    echo "  应用日志: ./data/logs/"
    echo "  Redis 数据: ./data/redis/"

    echo ""
}

# 主逻辑
COMMAND=${1:-start}

case "$COMMAND" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_restart
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}未知命令: $COMMAND${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
