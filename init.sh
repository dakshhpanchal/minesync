#!/bin/bash

set -euo pipefail

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

info "Checking dependencies..."
for cmd in git java curl; do
    command -v "$cmd" &>/dev/null || error "$cmd is not installed. Please install it first."
done
success "All dependencies found."

info "Checking Java version..."
JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [[ "$JAVA_VER" -lt 21 ]]; then
    error "Java 21 or higher is required. You have Java $JAVA_VER."
fi
success "Java $JAVA_VER found."

info "Checking ZeroTier..."
if ! command -v zerotier-cli &>/dev/null; then
    error "ZeroTier is not installed. Run: curl -s https://install.zerotier.com | sudo bash"
fi

ZT_STATUS=$(sudo zerotier-cli listnetworks 2>/dev/null | grep "$ZEROTIER_NETWORK_ID" || true)
if [[ -z "$ZT_STATUS" ]]; then
    warn "Not joined to ZeroTier network. Joining now..."
    sudo zerotier-cli join "$ZEROTIER_NETWORK_ID" || error "Failed to join ZeroTier network."
    echo ""
    warn "You need to be approved by the network admin at my.zerotier.com"
    warn "Once approved, re-run this script."
    exit 0
fi

ZT_IP=$(ip addr show 2>/dev/null | grep -A2 'zt' | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -n1 || true)
if [[ -z "$ZT_IP" ]]; then
    error "ZeroTier joined but no IP assigned yet. Make sure you are approved on my.zerotier.com"
fi
success "ZeroTier active. Your IP: $ZT_IP"

if [[ -f "server.jar" ]]; then
    warn "server.jar already exists, skipping download."
else
    info "Downloading server.jar for Minecraft $MC_VERSION..."
    curl -# -L -o server.jar "$SERVER_JAR_URL" || error "Download failed."
    success "server.jar downloaded."
fi

info "Verifying required files..."
for f in eula.txt server.properties ops.json .server.lock; do
    [[ -f "$f" ]] || error "$f is missing from the repo!"
done
success "All required files present."

echo ""
echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo -e "Run ${CYAN}./server.sh start${NC} to start the server."
