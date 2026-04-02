# 🧱 Minecraft World — Shared Server

A self-managed Minecraft 1.21.11 server shared between 4 players.
World data is synced via GitHub. Only one person hosts at a time.

---

## How it works

- World data lives on this GitHub repo
- Anyone can become the host at any time
- When you start the server, a lock is written to GitHub so no one else can start
- When you stop the server, the world is pushed to GitHub and the lock is released
- Others connect via the host's public IP using port forwarding

---

## First time setup (everyone does this)

### 1. Prerequisites
- Git installed
- Java 21 or higher installed
- Minecraft Java Edition 1.21.11

### 2. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/minecraft-world.git
cd minecraft-world
```

### 3. Create your player.config
Create a file called `player.config` in the repo folder (it's gitignored, so it's yours only):
```bash
PLAYER_NAME="YourNameHere"
GITHUB_REPO="https://github.com/YOUR_USERNAME/minecraft-world.git"
GITHUB_BRANCH="main"
MC_VERSION="1.21.11"
SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
MC_RAM_MIN="2G"
MC_RAM_MAX="4G"
SERVER_PORT=25565
```

### 4. Run init
```bash
chmod +x init.sh server.sh
./init.sh
```

---

## Starting the server
```bash
./server.sh start
```

- Pulls latest world from GitHub
- Checks no one else is hosting
- Fetches your public IP
- Writes the lock file
- Starts the Minecraft server

---

## Stopping the server

Either type `stop` in the Minecraft server console, or run in another terminal:
```bash
./server.sh stop
```

This will automatically push the world data to GitHub and release the lock.

---

## Checking who is hosting
```bash
./server.sh status
```

---

## Connecting as a player (not hosting)

1. Run `./server.sh status` to get the host's IP
2. Open Minecraft → Multiplayer → Add Server
3. Enter `IP:25565`
4. Join!

---

## Port forwarding

The host needs to forward **port 25565 (TCP)** on their router to their local machine.
Search: `how to port forward on [your router brand]`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `player.config not found` | Create it as shown above |
| `server is already being hosted` | Run `./server.sh status` to see who |
| `git pull failed` | Check your internet / GitHub access |
| `Java 21 required` | Install Java 21 from adoptium.net |
| Friends can't connect | Make sure port 25565 is forwarded on your router |