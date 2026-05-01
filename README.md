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

## Stack

- **Server:** Fabric 1.21.11
- **Mods (server + client):** Simple Voice Chat, Fabric API
- **Client only:** Sodium (performance), Iris (shaders, optional)
- **Networking:** NetBird overlay VPN

---

## NetBird Setup (everyone, once)

### 1. Get the Setup Key
Ask the repo owner for the **NetBird Setup Key** from app.netbird.io → Setup Keys.

### 2. Install NetBird

```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sh
sudo netbird up --setup-key YOUR_SETUP_KEY
```

### 3. Verify

```bash
netbird status
```

You should see `Status: Connected` and an IP like `100.x.x.x`

---

## First Time Setup (everyone)

### Prerequisites

| Requirement | Install |
|---|---|
| Git | `sudo apt install git` |
| Java 21+ | `sudo apt install openjdk-21-jdk` |
| Python 3 | usually pre-installed |
| NetBird | see above |

### 1. Clone the repo

```bash
git clone https://github.com/dakshhpanchal/minesync.git
cd minesync
```

### 2. Create `player.config`

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

```bash
chmod +x init.sh server.sh
./init.sh
```

This will:
- Download the Fabric server installer and run it
- Download server-side mods into `mods/`
- Verify all required files are present

---

## Starting the Server

```bash
./server.sh start
```

- Pulls latest world from GitHub
- Checks no one else is hosting
- Gets your NetBird IP
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

1. Make sure NetBird is running (`netbird status`)
2. Run `./server.sh status` to get the host's IP
3. Minecraft → Multiplayer → Add Server → `IP:25565`

---

## Client Mod Setup (everyone, once)

The server runs Fabric, so each player needs a Fabric profile in their launcher with these mods installed.

### 1. Create a Fabric 1.21.11 profile in your launcher

In TLauncher, select `Fabric 1.21.11` as the version when creating a new profile.

### 2. Download these mods into `~/.minecraft/mods/`

| Mod | Purpose | Download |
|---|---|---|
| Fabric API | Required by all mods | [fabric-api-0.141.3+1.21.11.jar](https://cdn.modrinth.com/data/P7dR8mSH/versions/i5tSkVBH/fabric-api-0.141.3%2B1.21.11.jar) |
| Simple Voice Chat | In-game voice chat | [voicechat-fabric-1.21.11-2.6.9.jar](https://cdn.modrinth.com/data/9eGKb6K1/versions/YECcGHNV/voicechat-fabric-1.21.11-2.6.9.jar) |
| Sodium | Performance (replaces OptiFine) | [sodium-fabric-0.8.7+mc1.21.11.jar](https://cdn.modrinth.com/data/AANobbMI/versions/UddlN6L4/sodium-fabric-0.8.7%2Bmc1.21.11.jar) |
| Iris *(optional)* | Shader pack support | [modrinth.com/mod/iris](https://modrinth.com/mod/iris/versions?g=1.21.11) |

### 3. Launch the Fabric profile and connect

Voice chat keybind is **V** by default. You should see a speaker icon when someone is talking.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `NetBird IP not found` | `sudo netbird up --setup-key YOUR_KEY` |
| `Server already being hosted` | Run `./server.sh status` to see who |
| `Git pull failed` | Check internet / GitHub access |
| `Java 21 required` | `sudo apt install openjdk-21-jdk` |
| Friends can't connect | Make sure they're on NetBird (`netbird status`) |
| `player.config not found` | Create it as shown above |
| Voice chat not working | Press V → Settings → check mic input level bar moves when you talk |
| Stuck on loading screen | Make sure you launched the Fabric profile, not OptiFine/vanilla |

---

## Important Rules

- Only one person hosts at a time
- Always stop the server properly — don't just close the terminal
- Never push with `git push --force`
- Never edit `.server.lock` manually

---

## .gitignore

Make sure your `.gitignore` includes:

```
libraries/
.fabric/
logs/
crash-reports/
fabric-installer.jar
```