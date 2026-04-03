# MineSync

A self-managed Minecraft 1.21.11 server for 4 players.
World data syncs via GitHub. Networking via ZeroTier (no port forwarding, works on hotspots).

Repository: https://github.com/dakshhpanchal/minesync

---

## How It Works

- World data lives on this GitHub repo
- Anyone can become the host at any time
- Starting the server claims a lock on GitHub — no one else can start until it's released
- Stopping the server pushes the world to GitHub and releases the lock
- Players connect via ZeroTier private IP — no port forwarding needed

---

## ZeroTier Setup (everyone, once)

### 1. Get the Network ID
Ask the repo owner for the **ZeroTier Network ID**.

### 2. Install ZeroTier

**Linux:**
```bash
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join YOUR_NETWORK_ID
```

**Windows:**
- Download from zerotier.com/download
- Install, open system tray icon → Join Network → paste Network ID

### 3. Get approved
Tell the repo owner your device appeared in the network.
They'll approve you at my.zerotier.com → Networks → Members → check Auth.

### 4. Verify
```bash
# Linux - check your ZeroTier IP
ip addr show zt0 | grep 'inet '
```
You should see an IP like `192.168.196.x`

---

## First Time Setup (everyone)

### Prerequisites
- Git
- Java 21+
- Minecraft Java Edition 1.21.11
- ZeroTier (see above)

### 1. Clone the repo
```bash
git clone https://github.com/dakshhpanchal/minesync.git
cd minesync
```

### 2. Create `player.config`
```bash
PLAYER_NAME="YourNameHere"
GITHUB_REPO="https://github.com/dakshhpanchal/minesync.git"
GITHUB_BRANCH="main"
MC_VERSION="1.21.11"
SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
MC_RAM_MIN="2G"
MC_RAM_MAX="4G"
SERVER_PORT=25565
ZEROTIER_NETWORK_ID="YOUR_NETWORK_ID_HERE"
```

### 3. Run init
```bash
chmod +x init.sh server.sh
./init.sh
```

---

## Starting the Server
```bash
./server.sh start
```

- Pulls latest world from GitHub
- Checks no one else is hosting
- Gets your ZeroTier IP
- Claims the lock
- Starts Minecraft server

---

## Stopping the Server

Type `stop` in the Minecraft server console, or in another terminal:
```bash
./server.sh stop
```

Automatically pushes world data and releases the lock.

---

## Checking Who Is Hosting
```bash
./server.sh status
```

---

## Connecting as a Player

1. Make sure ZeroTier is running
2. Run `./server.sh status` to get the host's IP
3. Minecraft → Multiplayer → Add Server → `IP:25565`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ZeroTier IP not found` | Run `sudo zerotier-cli join NETWORK_ID` and get approved |
| `Server already being hosted` | Run `./server.sh status` to see who |
| `Git pull failed` | Check internet / GitHub access |
| `Java 21 required` | Install from adoptium.net |
| Friends can't connect | Make sure they're approved on ZeroTier network |
| `player.config not found` | Create it as shown above |

---

## Important Rules

- Only one person hosts at a time
- Always stop the server properly — don't just close the terminal
- Never push with `git push --force`
- Never edit `.server.lock` manually
