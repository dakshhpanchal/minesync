# MineSync

MineSync is a self-managed Minecraft 1.21.11 server designed for shared hosting among multiple players.
World data is synchronized via a single GitHub repository, and connectivity is handled using Tailscale to eliminate the need for port forwarding or public IP configuration.

Repository: https://github.com/dakshhpanchal/minesync

---

## Overview

MineSync enables a group of players to collaboratively host and play on the same Minecraft world. Any participant can become the host, but only one host can be active at a time. World state is synchronized through Git, ensuring consistency across sessions.

---

## Architecture

* Single shared GitHub repository (this repository)
* All players are collaborators with write access
* A lock file ensures only one active host
* World data is pulled on start and pushed on stop
* Connectivity is established using Tailscale (shared private network)

---

## How It Works

1. A player starts the server:

   * Pulls latest world data from GitHub
   * Checks if another host is active
   * Acquires lock by updating `.server.lock`
   * Starts the Minecraft server

2. Other players:

   * Retrieve host IP using `./server.sh status`
   * Connect using Tailscale IP

3. When the host stops:

   * World data is committed and pushed
   * Lock is released

---

## Repository Model (Important)

This project requires a **single shared repository**.

### Rules:

* All players must clone **this repository only**
* All players must be added as **collaborators**
* Do not fork the repository
* Do not create separate copies

### Why:

* `.server.lock` must be globally consistent
* Minecraft world files cannot be merged safely
* Multiple repositories will cause world divergence and corruption

---

## Prerequisites

Each participant must have:

* Git installed
* Java 21 or higher installed
* Minecraft Java Edition 1.21.11
* A Tailscale account (individual account per user)

---

## Tailscale Setup (Required)

MineSync uses Tailscale to create a private network between players.

### Step 1: Create an Account

Each player must create their own Tailscale account using:

* Google
* GitHub
* Microsoft
* or other supported identity providers

---

### Step 2: Join the Same Tailnet

One player (project owner) creates the tailnet.

Other players must be invited:

* Open Tailscale admin console
* Invite users via email
* Accept invitation on each account

All players must appear in the **same tailnet**.

---

### Step 3: Install Tailscale

On each machine:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Login via browser when prompted.

---

### Step 4: Verify Connectivity

Run:

```bash
tailscale status
```

You should see all other players listed.

Get your IP:

```bash
tailscale ip -4
```

Example:

```
100.101.102.103
```

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/dakshhpanchal/minesync.git
cd minesync
```

---

### 2. Create `player.config`

Create a file named `player.config` in the project directory:

```bash
PLAYER_NAME="YourNameHere"
GITHUB_REPO="https://github.com/dakshhpanchal/minesync.git"
GITHUB_BRANCH="main"
MC_VERSION="1.21.11"
SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
MC_RAM_MIN="2G"
MC_RAM_MAX="4G"
SERVER_PORT=25565
```

---

### 3. Initialize

```bash
chmod +x init.sh server.sh
./init.sh
```

---

## Starting the Server

```bash
./server.sh start
```

This will:

* Pull latest world data
* Check lock status
* Detect Tailscale IP
* Acquire lock
* Start the Minecraft server

Output example:

```
Using Tailscale IP: 100.x.x.x
Connect via Tailscale: 100.x.x.x:25565
```

---

## Stopping the Server

Stop using:

* `stop` inside Minecraft console
  or

```bash
./server.sh stop
```

This will:

* Stop the server process
* Push world data to GitHub
* Release the lock

---

## Checking Server Status

```bash
./server.sh status
```

Displays:

* Current host
* Tailscale IP
* Session start time

---

## Connecting as a Player

1. Ensure Tailscale is running:

   ```bash
   tailscale status
   ```

2. Get server details:

   ```bash
   ./server.sh status
   ```

3. Copy the IP shown

4. In Minecraft:

   * Multiplayer → Add Server
   * Enter: `IP:25565`

---

## Network Model

```
Host → Tailscale → Players
```

This ensures:

* No port forwarding required
* Works on mobile hotspots
* Works behind CGNAT
* Only invited users can access the network

---

## Troubleshooting

| Problem               | Resolution                            |
| --------------------- | ------------------------------------- |
| Cannot connect        | Ensure both users are in same tailnet |
| Device not visible    | Check `tailscale status`              |
| Not in network        | Accept tailnet invite                 |
| No Tailscale IP       | Run `sudo tailscale up`               |
| Server already active | Run `./server.sh status`              |
| Git errors            | Verify repository access              |
| Java error            | Install Java 21+                      |

---

## Safety Notes

* Only one host must run the server at a time
* Do not force push (`git push --force`)
* Do not modify `.server.lock` manually
* Always stop the server properly to avoid data loss

---

## Summary

MineSync provides:

* Shared Minecraft hosting
* Git-based world synchronization
* Lock-based concurrency control
* Secure private networking via Tailscale

This design ensures reliable operation across different networks without requiring router configuration.
