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

# ── Mod CDN URLs ────────────────────────────────────────────────────────────
FABRIC_INSTALLER_URL="https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.jar"
FABRIC_API_URL="https://cdn.modrinth.com/data/P7dR8mSH/versions/i5tSkVBH/fabric-api-0.141.3%2B1.21.11.jar"
FABRIC_API_JAR="fabric-api-0.141.3+1.21.11.jar"
VOICECHAT_URL="https://cdn.modrinth.com/data/9eGKb6K1/versions/YECcGHNV/voicechat-fabric-1.21.11-2.6.9.jar"
VOICECHAT_JAR="voicechat-fabric-1.21.11-2.6.9.jar"
# ────────────────────────────────────────────────────────────────────────────

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

# ── Fabric server setup ──────────────────────────────────────────────────────
# The Fabric installer produces two files:
#   server.jar                → vanilla Minecraft jar (Fabric reads this internally)
#   fabric-server-launch.jar  → the actual Fabric launcher (what we run)
# We must NOT rename fabric-server-launch.jar — it would overwrite the vanilla jar.
if [[ -f "fabric-server-launch.jar" ]]; then
    warn "fabric-server-launch.jar already exists, skipping Fabric install."
else
    info "Downloading Fabric installer..."
    curl -# -L -o fabric-installer.jar "$FABRIC_INSTALLER_URL" || error "Fabric installer download failed."

    info "Running Fabric installer for Minecraft $MC_VERSION..."
    java -jar fabric-installer.jar server -mcversion "$MC_VERSION" -downloadMinecraft || error "Fabric install failed."

    rm -f fabric-installer.jar
    success "Fabric server installed (fabric-server-launch.jar + server.jar)."
fi

# ── Mods folder and downloads ────────────────────────────────────────────────
mkdir -p mods

if [[ -f "mods/$FABRIC_API_JAR" ]]; then
    warn "Fabric API already present, skipping."
else
    info "Downloading Fabric API..."
    curl -# -L -o "mods/$FABRIC_API_JAR" "$FABRIC_API_URL" || error "Fabric API download failed."
    success "Fabric API downloaded."
fi

if [[ -f "mods/$VOICECHAT_JAR" ]]; then
    warn "Simple Voice Chat already present, skipping."
else
    info "Downloading Simple Voice Chat..."
    curl -# -L -o "mods/$VOICECHAT_JAR" "$VOICECHAT_URL" || error "Simple Voice Chat download failed."
    success "Simple Voice Chat downloaded."
fi

info "Verifying required files..."
for f in eula.txt server.properties ops.json .server.lock; do
    [[ -f "$f" ]] || error "$f is missing from the repo!"
done
success "All required files present."

echo ""
echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo -e "Run ${CYAN}./server.sh start${NC} to start the server."
echo ""
echo -e "${BOLD}Client-side mods for each player (install in TLauncher Fabric profile):${NC}"
echo -e "  ${CYAN}https://modrinth.com/mod/fabric-api${NC}             (Fabric API)"
echo -e "  ${CYAN}https://modrinth.com/plugin/simple-voice-chat${NC}   (Simple Voice Chat)"
echo -e "  ${CYAN}https://modrinth.com/mod/sodium${NC}                 (Sodium - replaces OptiFine)"
echo -e "  ${CYAN}https://modrinth.com/mod/iris${NC}                   (Iris - shaders support, optional)"
echo ""