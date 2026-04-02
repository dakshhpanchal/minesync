#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

if [[ ! -f "player.config" ]]; then
    error "player.config not found! Create it before running this."
fi
source player.config

LOCK_FILE=".server.lock"
PID_FILE=".server.pid"
CLEANED_UP=false

get_public_ip() {
    IP=$(curl -s --max-time 5 https://ifconfig.me) \
    || IP=$(curl -s --max-time 5 https://api.ipify.org) \
    || error "Could not fetch public IP."
    echo "$IP"
}

get_tailscale_ip() {
    tailscale ip -4 2>/dev/null | head -n1 || true
}

lock_get() {
    python3 -c "import json; d=json.load(open('$LOCK_FILE')); print(d.get('$1',''))" 2>/dev/null || echo ""
}

cleanup_on_exit() {
    echo ""
    warn "Interrupt received. Cleaning up..."

    if [[ -f "$PID_FILE" ]]; then
        MC_PID=$(cat "$PID_FILE")
        if kill -0 "$MC_PID" 2>/dev/null; then
            kill "$MC_PID" 2>/dev/null || true
            wait "$MC_PID" 2>/dev/null || true
        fi
    fi

    cmd_stop_cleanup
    exit 0
}

trap cleanup_on_exit INT TERM

cmd_start() {
    info "Pulling latest world data from GitHub..."
    git pull origin "$GITHUB_BRANCH" || error "Git pull failed."

    LOCK_HOST=$(lock_get "host")
    if [[ -n "$LOCK_HOST" ]]; then
        LOCK_IP=$(lock_get "ip")
        LOCK_SINCE=$(lock_get "since")
        echo ""
        echo -e "${RED}Server is already being hosted!${NC}"
        echo -e "  Host  : ${BOLD}$LOCK_HOST${NC}"
        echo -e "  IP    : ${BOLD}$LOCK_IP:$SERVER_PORT${NC}"
        echo -e "  Since : ${BOLD}$LOCK_SINCE${NC}"
        echo ""
        error "Stop the server on $LOCK_HOST's machine first."
    fi

    info "Fetching connection IP (Tailscale required)..."

    TS_IP=$(get_tailscale_ip)
    [[ -z "$TS_IP" ]] && error "Tailscale not running. Run: sudo tailscale up"

    PUBLIC_IP="$TS_IP"
    success "Using Tailscale IP: $PUBLIC_IP"

    info "Claiming server lock..."
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$LOCK_FILE" <<EOF
{
  "host": "$PLAYER_NAME",
  "since": "$TIMESTAMP",
  "ip": "$PUBLIC_IP"
}
EOF

    git add "$LOCK_FILE"
    git commit -m "LOCK: $PLAYER_NAME started the server"
    git push origin "$GITHUB_BRANCH" || error "Could not push lock file."
    success "Lock claimed and pushed."

    echo ""
    echo -e "${BOLD}${GREEN}Starting Minecraft $MC_VERSION server...${NC}"
    echo -e "Connect via Tailscale: ${CYAN}$PUBLIC_IP:$SERVER_PORT${NC}"
    echo -e "Press ${YELLOW}Ctrl+C${NC} or type ${YELLOW}stop${NC} to stop.\n"

    java -Xms"$MC_RAM_MIN" -Xmx"$MC_RAM_MAX" -jar server.jar nogui &
    MC_PID=$!
    echo "$MC_PID" > "$PID_FILE"

    wait "$MC_PID" || true

    cmd_stop_cleanup
}

cmd_stop_cleanup() {
    $CLEANED_UP && return
    CLEANED_UP=true

    echo ""
    info "Server stopped. Waiting for world to flush..."
    sleep 2
    sync
    sleep 1
    info "Pushing world data..."

    rm -f "$PID_FILE"
    echo "{}" > "$LOCK_FILE"

    git add -A
    git commit -m "SAVE: $PLAYER_NAME ended the session" || warn "Nothing to commit."
    git push origin "$GITHUB_BRANCH" || warn "Push failed."

    success "World data pushed."
    success "Lock released."
}

cmd_stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        warn "No PID file found."
        exit 0
    fi

    MC_PID=$(cat "$PID_FILE")

    if kill -0 "$MC_PID" 2>/dev/null; then
        info "Stopping server (PID $MC_PID)..."
        kill "$MC_PID"
        wait "$MC_PID" 2>/dev/null || true
        success "Server stopped."
    else
        warn "Process not found."
    fi

    cmd_stop_cleanup
}

cmd_status() {
    git pull origin "$GITHUB_BRANCH" -q || warn "Could not sync status."

    LOCK_HOST=$(lock_get "host")

    echo ""
    if [[ -z "$LOCK_HOST" ]]; then
        echo -e "${GREEN}${BOLD}Server is FREE${NC}"
    else
        LOCK_IP=$(lock_get "ip")
        LOCK_SINCE=$(lock_get "since")
        echo -e "${YELLOW}${BOLD}Server is ACTIVE${NC}"
        echo -e "  Host  : ${BOLD}$LOCK_HOST${NC}"
        echo -e "  IP    : ${BOLD}$LOCK_IP:$SERVER_PORT${NC}"
        echo -e "  Since : ${BOLD}$LOCK_SINCE${NC}"
        echo ""
        echo -e "Connect via Tailscale: ${CYAN}$LOCK_IP:$SERVER_PORT${NC}"
    fi
    echo ""
}

case "${1:-}" in
    start)  cmd_start  ;;
    stop)   cmd_stop   ;;
    status) cmd_status ;;
    *)
        echo -e "Usage: ${CYAN}./server.sh [start|stop|status]${NC}"
        exit 1
        ;;
esac