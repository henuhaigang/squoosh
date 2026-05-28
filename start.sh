#!/usr/bin/env bash
set -e

PORT=3000
DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/.squoosh.pid"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 停止已运行的服务
stop() {
  if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
      info "停止已运行的服务 (PID: $OLD_PID)"
      kill "$OLD_PID" 2>/dev/null
      sleep 1
    fi
    rm -f "$PID_FILE"
  fi
}

# 检查 Node.js
check_node() {
  if ! command -v node &>/dev/null; then
    error "未找到 Node.js，请先安装 Node.js >= 20.x\n   下载地址: https://nodejs.org"
  fi
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_VER" -lt 20 ]; then
    error "Node.js 版本过低 ($(node -v))，需要 >= 20.x"
  fi
  info "Node.js 版本: $(node -v)"
}

# 安装依赖
install_deps() {
  if [ ! -d "$DIR/node_modules" ]; then
    info "首次运行，正在安装依赖..."
    cd "$DIR" && npm ci --silent
    info "依赖安装完成"
  fi
}

# 构建
build() {
  if [ ! -d "$DIR/build" ] || [ ! -f "$DIR/build/index.html" ]; then
    info "正在构建项目..."
    cd "$DIR" && npm run build
    info "构建完成"
  fi
}

# 启动
start() {
  stop
  check_node
  install_deps
  build

  info "启动服务，端口: $PORT"
  nohup npx serve "$DIR/build" -l "$PORT" > /tmp/squoosh-serve.log 2>&1 &
  SERVER_PID=$!
  echo "$SERVER_PID" > "$PID_FILE"

  sleep 2
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    echo ""
    info "服务启动成功!"
    echo -e "   本机访问: ${GREEN}http://localhost:${PORT}${NC}"
    LAN_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    if [ -n "$LAN_IP" ]; then
      echo -e "   局域网:   ${GREEN}http://${LAN_IP}:${PORT}${NC}"
    fi
    echo -e "   停止服务: ${YELLOW}./start.sh stop${NC}"
    echo ""
  else
    error "服务启动失败，请查看日志: /tmp/squoosh-serve.log"
  fi
}

# 主逻辑
CMD="${1:-start}"
# 如果第一个参数是数字，当作端口，命令默认为 start
if [[ "$CMD" =~ ^[0-9]+$ ]]; then
  PORT="$CMD"
  CMD="start"
fi

case "$CMD" in
  start)
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      PORT="$2"
    fi
    start
    ;;
  stop)
    stop
    info "服务已停止"
    ;;
  restart)
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      PORT="$2"
    fi
    start
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      info "服务正在运行 (PID: $(cat "$PID_FILE"))"
    else
      warn "服务未运行"
    fi
    ;;
  *)
    echo "用法: ./start.sh [start|stop|restart|status] [端口号]"
    echo "  start [端口]  启动服务（默认端口 3000）"
    echo "  stop          停止服务"
    echo "  restart [端口] 重启服务"
    echo "  status        查看运行状态"
    echo ""
    echo "  ./start.sh          启动服务（默认端口 3000）"
    echo "  ./start.sh 8080     启动服务（端口 8080）"
    echo "  ./start.sh stop     停止服务"
    ;;
esac
