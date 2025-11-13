#!/bin/bash

# ======================================
# 自定义模型快速添加脚本
# ======================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
RELAY_URL="${RELAY_URL:-http://localhost:3000}"
ADMIN_SESSION=""

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Claude Relay Service - 自定义模型添加工具${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# 检查jq是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}错误: 需要安装 jq 工具${NC}"
    echo "安装方法:"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  CentOS/RHEL: sudo yum install jq"
    echo "  macOS: brew install jq"
    exit 1
fi

# 获取管理员会话token
get_admin_session() {
    echo -e "${YELLOW}请输入管理员凭据${NC}"
    read -p "管理员用户名: " ADMIN_USER
    read -sp "管理员密码: " ADMIN_PASS
    echo ""

    echo -e "${BLUE}正在登录...${NC}"
    RESPONSE=$(curl -s -X POST "$RELAY_URL/admin/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}")

    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        ADMIN_SESSION=$(echo "$RESPONSE" | jq -r '.session')
        echo -e "${GREEN}✓ 登录成功${NC}"
    else
        echo -e "${RED}✗ 登录失败: $(echo $RESPONSE | jq -r '.message')${NC}"
        exit 1
    fi
}

# 添加模型账户
add_model_account() {
    local name=$1
    local endpoint=$2
    local deployment=$3
    local api_key=$4
    local model_mapping=$5
    local description=$6

    echo -e "${BLUE}正在添加模型: $name${NC}"

    RESPONSE=$(curl -s -X POST "$RELAY_URL/admin/azure-openai-accounts" \
        -H "Content-Type: application/json" \
        -H "Cookie: admin_session=$ADMIN_SESSION" \
        -d "{
            \"name\": \"$name\",
            \"description\": \"$description\",
            \"accountType\": \"shared\",
            \"azureEndpoint\": \"$endpoint\",
            \"apiVersion\": \"2024-02-01\",
            \"deploymentName\": \"$deployment\",
            \"apiKey\": \"$api_key\",
            \"supportedModels\": [\"$model_mapping\"],
            \"priority\": 50,
            \"isActive\": true,
            \"schedulable\": true
        }")

    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        ACCOUNT_ID=$(echo "$RESPONSE" | jq -r '.account.id')
        echo -e "${GREEN}✓ 模型添加成功 (ID: $ACCOUNT_ID)${NC}"
        return 0
    else
        echo -e "${RED}✗ 添加失败: $(echo $RESPONSE | jq -r '.message')${NC}"
        return 1
    fi
}

# 测试模型连接
test_model_connection() {
    local endpoint=$1
    local deployment=$2
    local api_key=$3

    echo -e "${BLUE}测试模型连接: $endpoint${NC}"

    # 简单的健康检查
    if curl -s --max-time 5 "$endpoint/v1/models" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 端点可访问${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ 端点不可访问或超时,但仍会尝试添加${NC}"
        return 1
    fi
}

# 交互式添加单个模型
add_single_model() {
    echo ""
    echo -e "${YELLOW}请输入模型信息:${NC}"
    echo ""

    read -p "模型名称 (如: Qwen3-32B): " MODEL_NAME
    read -p "API端点 (如: http://192.168.1.100:8000): " MODEL_ENDPOINT
    read -p "部署名称 (如: qwen3-32b): " MODEL_DEPLOYMENT
    read -p "API Key (无需认证可随意填写): " MODEL_API_KEY

    echo ""
    echo -e "${YELLOW}选择映射到的Claude模型:${NC}"
    echo "1) claude-3-opus-20240229 (最强)"
    echo "2) claude-3-sonnet-20240229 (平衡)"
    echo "3) claude-3-haiku-20240307 (快速)"
    read -p "请选择 (1-3): " MODEL_CHOICE

    case $MODEL_CHOICE in
        1) MODEL_MAPPING="claude-3-opus-20240229" ;;
        2) MODEL_MAPPING="claude-3-sonnet-20240229" ;;
        3) MODEL_MAPPING="claude-3-haiku-20240307" ;;
        *)
            echo -e "${RED}无效选择,使用默认: claude-3-opus-20240229${NC}"
            MODEL_MAPPING="claude-3-opus-20240229"
            ;;
    esac

    read -p "描述 (可选): " MODEL_DESC
    MODEL_DESC=${MODEL_DESC:-"自定义部署的 $MODEL_NAME 模型"}

    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}确认模型信息:${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo "名称: $MODEL_NAME"
    echo "端点: $MODEL_ENDPOINT"
    echo "部署: $MODEL_DEPLOYMENT"
    echo "映射: $MODEL_MAPPING"
    echo "描述: $MODEL_DESC"
    echo ""

    read -p "确认添加? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo -e "${YELLOW}已取消${NC}"
        return 1
    fi

    # 测试连接
    test_model_connection "$MODEL_ENDPOINT" "$MODEL_DEPLOYMENT" "$MODEL_API_KEY"

    # 添加账户
    add_model_account \
        "$MODEL_NAME" \
        "$MODEL_ENDPOINT" \
        "$MODEL_DEPLOYMENT" \
        "$MODEL_API_KEY" \
        "$MODEL_MAPPING" \
        "$MODEL_DESC"
}

# 从配置文件批量添加
batch_add_models() {
    local config_file=$1

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}错误: 配置文件不存在: $config_file${NC}"
        return 1
    fi

    echo -e "${BLUE}从配置文件批量添加模型: $config_file${NC}"
    echo ""

    # 读取配置文件并逐个添加
    cat "$config_file" | jq -c '.models[]' | while read model; do
        NAME=$(echo $model | jq -r '.name')
        ENDPOINT=$(echo $model | jq -r '.endpoint')
        DEPLOYMENT=$(echo $model | jq -r '.deployment')
        MAPPING=$(echo $model | jq -r '.mapping')
        DESC=$(echo $model | jq -r '.description // empty')
        API_KEY=$(echo $model | jq -r '.apiKey // "sk-custom"')

        DESC=${DESC:-"自定义部署的 $NAME 模型"}

        echo ""
        echo -e "${YELLOW}添加模型: $NAME${NC}"

        add_model_account \
            "$NAME" \
            "$ENDPOINT" \
            "$DEPLOYMENT" \
            "$API_KEY" \
            "$MAPPING" \
            "$DESC"

        sleep 1
    done

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}批量添加完成!${NC}"
    echo -e "${GREEN}======================================${NC}"
}

# 创建示例配置文件
create_example_config() {
    local config_file="custom-models.example.json"

    cat > "$config_file" <<'EOF'
{
  "models": [
    {
      "name": "Qwen3-VL-235B",
      "endpoint": "http://192.168.1.100:8000",
      "deployment": "qwen3-vl-235b",
      "apiKey": "sk-custom",
      "mapping": "claude-3-opus-20240229",
      "description": "Qwen3-VL多模态模型"
    },
    {
      "name": "Qwen3-32B",
      "endpoint": "http://192.168.1.101:8000",
      "deployment": "qwen3-32b",
      "apiKey": "sk-custom",
      "mapping": "claude-3-sonnet-20240229",
      "description": "Qwen3对话模型"
    },
    {
      "name": "GLM-4.6-FP8",
      "endpoint": "http://192.168.1.102:8000",
      "deployment": "glm-4.6-fp8",
      "apiKey": "sk-custom",
      "mapping": "claude-3-haiku-20240307",
      "description": "GLM-4.6量化模型"
    },
    {
      "name": "Qwen3-Coder-480B",
      "endpoint": "http://192.168.1.103:8000",
      "deployment": "qwen3-coder-480b",
      "apiKey": "sk-custom",
      "mapping": "claude-3-opus-20240229",
      "description": "Qwen3代码生成模型"
    }
  ]
}
EOF

    echo -e "${GREEN}✓ 已创建示例配置文件: $config_file${NC}"
    echo ""
    echo "请编辑此文件,填入您的实际模型信息,然后运行:"
    echo -e "${BLUE}  ./add-custom-model.sh --batch $config_file${NC}"
}

# 列出所有账户
list_accounts() {
    echo -e "${BLUE}获取账户列表...${NC}"

    RESPONSE=$(curl -s -X GET "$RELAY_URL/admin/azure-openai-accounts" \
        -H "Cookie: admin_session=$ADMIN_SESSION")

    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}Azure OpenAI 账户列表:${NC}"
        echo "$RESPONSE" | jq -r '.accounts[] | "ID: \(.id) | 名称: \(.name) | 端点: \(.azureEndpoint) | 状态: \(.isActive)"'
    else
        echo -e "${RED}获取失败${NC}"
    fi
}

# 主菜单
show_menu() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}请选择操作:${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo "1) 添加单个模型"
    echo "2) 批量导入模型"
    echo "3) 创建示例配置文件"
    echo "4) 列出所有账户"
    echo "5) 退出"
    echo ""
    read -p "请选择 (1-5): " CHOICE

    case $CHOICE in
        1)
            add_single_model
            show_menu
            ;;
        2)
            read -p "配置文件路径: " CONFIG_FILE
            batch_add_models "$CONFIG_FILE"
            show_menu
            ;;
        3)
            create_example_config
            show_menu
            ;;
        4)
            list_accounts
            show_menu
            ;;
        5)
            echo -e "${GREEN}再见!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            show_menu
            ;;
    esac
}

# 命令行参数处理
if [ "$1" == "--batch" ]; then
    if [ -z "$2" ]; then
        echo -e "${RED}错误: 请指定配置文件${NC}"
        echo "用法: $0 --batch <config-file.json>"
        exit 1
    fi
    get_admin_session
    batch_add_models "$2"
elif [ "$1" == "--example" ]; then
    create_example_config
elif [ "$1" == "--list" ]; then
    get_admin_session
    list_accounts
else
    # 交互式模式
    get_admin_session
    show_menu
fi
