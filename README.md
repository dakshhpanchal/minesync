# MineSync

A self-managed Minecraft 1.21.11 server for 4 players.
World data syncs via GitHub. Networking via NetBird (no port forwarding, works on hotspots).

Repository: https://github.com/dakshhpanchal/minesync

---

## How It Works

- World data lives on this GitHub repo
- Anyone can become the host at any time
- Starting the server claims a lock on GitHub — no one else can start until it's released
- Stopping the server pushes the world to GitHub and releases the lock
- Players connect via NetBird private IP — no port forwarding needed

---

## NetBird Setup (everyone, once)

### 1. Get the Setup Key
Ask the repo owner for the **NetBird Setup Key** from app.netbird.io → Setup Keys.

### 2. Install NetBird

**Linux:**
```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sh
sudo netbird up --setup-key YOUR_SETUP_KEY
```

**Windows:**
- Download and install from [netbird.io/download](https://netbird.io/download)
- Open Command Prompt and run:
```cmd
netbird up --setup-key YOUR_SETUP_KEY
```

### 3. Verify

```
netbird status
```

You should see `Status: Connected` and an IP like `100.x.x.x`

---

## First Time Setup (everyone)

### Prerequisites

| Requirement | Linux | Windows |
|---|---|---|
| Git | `sudo apt install git` | [git-scm.com](https://git-scm.com/download/win) |
| Java 21+ | `sudo apt install openjdk-21-jdk` | [adoptium.net](https://adoptium.net) |
| Python 3 | usually pre-installed | [Microsoft Store](https://apps.microsoft.com/store/search/python) or python.org |
| Minecraft Java 1.21.11 | via launcher | via launcher |
| NetBird | see above | see above |

### 1. Clone the repo

```bash
git clone https://github.com/dakshhpanchal/minesync.git
cd minesync
```

### 2. Create `player.config`

Same format on both platforms — create a plain text file named `player.config` in the repo folder:

```
PLAYER_NAME="YourNameHere"
GITHUB_REPO="https://github.com/dakshhpanchal/minesync.git"
GITHUB_BRANCH="main"
MC_VERSION="1.21.11"
SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
MC_RAM_MIN="2G"
MC_RAM_MAX="4G"
SERVER_PORT=25565
NETBIRD_SETUP_KEY="YOUR_SETUP_KEY_HERE"
```

### 3. Run init

**Linux:**
```bash
chmod +x init.sh server.sh
./init.sh
```

**Windows:**
```cmd
init.bat
```

---

## Starting the Server

**Linux:**
```bash
./server.sh start
```
**Windows:**
```cmd
server.bat start
```

- Pulls latest world from GitHub
- Checks no one else is hosting
- Gets your NetBird IP
- Claims the lock
- Starts Minecraft server

---

## Stopping the Server

Type `stop` in the Minecraft server console, or in another terminal:

**Linux:**
```bash
./server.sh stop
```
**Windows:**
```cmd
server.bat stop
```

Automatically pushes world data and releases the lock.

---

## Checking Who Is Hosting

**Linux:**
```bash
./server.sh status
```
**Windows:**
```cmd
server.bat status
```

---

## Connecting as a Player

1. Make sure NetBird is running (`netbird status`)
2. Run `status` (see above) to get the host's IP
3. Minecraft → Multiplayer → Add Server → `IP:25565`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `NetBird IP not found` | Linux: `sudo netbird up --setup-key YOUR_KEY` / Windows: `netbird up --setup-key YOUR_KEY` |
| `Server already being hosted` | Run `status` to see who |
| `Git pull failed` | Check internet / GitHub access |
| `Java 21 required` | Install from adoptium.net |
| Friends can't connect | Make sure they're connected to NetBird (`netbird status`) |
| `player.config not found` | Create it as shown above |
| Colors look broken on Windows | Run `reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1` then reopen terminal |
| Python not found on Windows | Install from Microsoft Store or python.org |

---

## Important Rules

- Only one person hosts at a time
- Always stop the server properly — don't just close the terminal/window
- Never push with `git push --force`
- Never edit `.server.lock` manually