#!/bin/bash

# QQ Farm Bot 一键部署脚本
# 支持 Docker 和 源码两种部署方式

set -e

PROJECT_NAME="qq-farm-bot"
DEFAULT_PORT=3007
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASS="admin"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 Docker 是否安装
check_docker() {
    if command_exists docker; then
        info "Docker 已安装：$(docker --version)"
        return 0
    else
        warn "Docker 未安装"
        return 1
    fi
}

# 检查 Docker Compose 是否安装
check_docker_compose() {
    if command_exists docker-compose; then
        info "Docker Compose 已安装：$(docker-compose --version)"
        return 0
    elif docker compose version >/dev/null 2>&1; then
        info "Docker Compose 已安装：$(docker compose version)"
        return 0
    else
        warn "Docker Compose 未安装"
        return 1
    fi
}

# 检查 Node.js 是否安装
check_nodejs() {
    if command_exists node; then
        local version=$(node -v)
        info "Node.js 已安装：$version"
        return 0
    else
        warn "Node.js 未安装"
        return 1
    fi
}

# 检查 pnpm 是否安装
check_pnpm() {
    if command_exists pnpm; then
        info "pnpm 已安装：$(pnpm -v)"
        return 0
    else
        warn "pnpm 未安装"
        return 1
    fi
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if command_exists ss; then
        if ss -tlnp | grep -q ":$port "; then
            return 1
        fi
    elif command_exists netstat; then
        if netstat -tlnp | grep -q ":$port "; then
            return 1
        fi
    fi
    return 0
}

# 生成随机密码
generate_password() {
    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16
}

# Docker 部署
deploy_docker() {
    info "======================"
    info "Docker 部署模式"
    info "======================"

    # 检查 Docker
    if ! check_docker; then
        error "请先安装 Docker"
        echo "访问 https://docs.docker.com/get-docker/ 了解安装方法"
        exit 1
    fi

    if ! check_docker_compose; then
        error "请先安装 Docker Compose"
        exit 1
    fi

    # 检查端口
    if ! check_port $DEFAULT_PORT; then
        warn "端口 $DEFAULT_PORT 已被占用"
        read -p "请输入新的端口号 (默认: $DEFAULT_PORT): " CUSTOM_PORT
        CUSTOM_PORT=${CUSTOM_PORT:-$DEFAULT_PORT}
        export PORT=$CUSTOM_PORT
        info "使用端口：$CUSTOM_PORT"
    else
        export PORT=$DEFAULT_PORT
    fi

    # 设置环境变量
    export TZ=${TZ:-Asia/Shanghai}
    export NODE_ENV=production

    info "开始构建 Docker 镜像..."
    docker compose build --no-cache

    info "启动容器..."
    docker compose up -d

    # 等待服务启动
    sleep 5

    info "查看容器状态..."
    docker compose ps

    success "Docker 部署完成！"
    echo ""
    echo "访问地址：http://<您的IP>:$PORT"
    echo "管理员账号：$DEFAULT_ADMIN_USER"
    echo "管理员密码：$DEFAULT_ADMIN_PASS"
    echo ""
    warn "请尽快修改默认密码！"
    echo ""
    echo "常用命令："
    echo "  查看日志：docker compose logs -f"
    echo "  停止服务：docker compose down"
    echo "  重启服务：docker compose restart"
    echo "  更新服务：docker compose pull && docker compose up -d"
}

# 源码部署
deploy_source() {
    info "======================"
    info "源码部署模式"
    info "======================"

    # 检查 Node.js
    if ! check_nodejs; then
        error "请先安装 Node.js 20+"
        echo "访问 https://nodejs.org/ 下载安装"
        exit 1
    fi

    # 检查 Node.js 版本
    local node_version=$(node -v | cut -d'.' -f1 | tr -d 'v')
    if [ "$node_version" -lt 20 ]; then
        error "需要 Node.js 20 或更高版本，当前版本：$(node -v)"
        exit 1
    fi

    # 检查 pnpm
    if ! check_pnpm; then
        info "尝试启用 corepack..."
        corepack enable
        if ! check_pnpm; then
            error "pnpm 未安装，请先安装 pnpm"
            echo "运行：npm install -g pnpm"
            exit 1
        fi
    fi

    # 检查端口
    if ! check_port $DEFAULT_PORT; then
        warn "端口 $DEFAULT_PORT 已被占用"
        read -p "请输入新的端口号 (默认: $DEFAULT_PORT): " CUSTOM_PORT
        CUSTOM_PORT=${CUSTOM_PORT:-$DEFAULT_PORT}
        export ADMIN_PORT=$CUSTOM_PORT
        info "使用端口：$CUSTOM_PORT"
    else
        export ADMIN_PORT=$DEFAULT_PORT
    fi

    # 设置环境变量
    export NODE_ENV=production

    info "安装依赖..."
    pnpm install

    info "构建前端..."
    pnpm build:web

    info "启动服务..."
    nohup pnpm dev:core > app.log 2>&1 &
    DISOWN_PID=$!
    disown $DISOWN_PID

    # 等待服务启动
    sleep 5

    success "源码部署完成！"
    echo ""
    echo "访问地址：http://<您的IP>:$ADMIN_PORT"
    echo "管理员账号：$DEFAULT_ADMIN_USER"
    echo "管理员密码：$DEFAULT_ADMIN_PASS"
    echo ""
    warn "请尽快修改默认密码！"
    echo ""
    echo "日志文件：$(pwd)/app.log"
    echo "查看日志：tail -f app.log"
    echo "停止服务：pkill -f 'qq-farm-bot'"
}

# 显示主菜单
show_menu() {
    echo ""
    echo "======================================"
    echo "  QQ Farm Bot 一键部署脚本"
    echo "======================================"
    echo ""
    echo "请选择部署方式："
    echo ""
    echo "1) Docker 部署 (推荐)"
    echo "2) 源码部署"
    echo "3) 退出"
    echo ""
    read -p "请输入选项 (1-3): " choice

    case $choice in
        1)
            deploy_docker
            ;;
        2)
            deploy_source
            ;;
        3)
            info "退出部署"
            exit 0
            ;;
        *)
            error "无效的选项"
            show_menu
            ;;
    esac
}

# 检查是否在正确的目录
check_directory() {
    if [ ! -f "package.json" ] || [ ! -f "docker-compose.yml" ]; then
        error "请在项目根目录运行此脚本"
        exit 1
    fi
}

# 主函数
main() {
    check_directory

    echo ""
    info "欢迎使用 QQ Farm Bot 一键部署脚本"
    info "项目：https://github.com/xue256964/qq-farm-bot"
    echo ""

    show_menu
}

# 执行主函数
main
