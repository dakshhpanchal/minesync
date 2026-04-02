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

if [[ -f "server.jar" ]]; then
    warn "server.jar already exists, skipping download."
else
    info "Downloading server.jar for Minecraft $MC_VERSION..."
    curl -# -L -o server.jar "$SERVER_JAR_URL" || error "Download failed. Check your internet connection or SERVER_JAR_URL in player.config."
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