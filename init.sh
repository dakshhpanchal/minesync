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

info "Checking NetBird..."
if ! command -v netbird &>/dev/null; then
    error "NetBird is not installed. Run: curl -fsSL https://pkgs.netbird.io/install.sh | sh"
fi

NB_STATUS=$(netbird status 2>/dev/null || true)
if echo "$NB_STATUS" | grep -q "Disconnected\|not connected"; then
    warn "NetBird is not connected. Connecting now..."
    sudo netbird up --setup-key "$NETBIRD_SETUP_KEY" || error "Failed to connect to NetBird network."
    sleep 3
fi

NB_IP=$(netbird status 2>/dev/null | grep -oP '(?<=IP: )\S+' | head -n1 || true)
if [[ -z "$NB_IP" ]]; then
    error "NetBird connected but no IP assigned yet. Check your setup key or approval at app.netbird.io"
fi
success "NetBird active. Your IP: $NB_IP"

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