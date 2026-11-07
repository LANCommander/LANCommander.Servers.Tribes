# Starsiege: Tribes Server (Docker)

This repository provides a Dockerized **Starsiege: Tribes** dedicated server. Tribes (Dynamix, 1998) has no Linux server, so the image runs the Windows game's own `-dedicated` mode under Wine.
The image builds on [`lancommander/wine`](https://github.com/LANCommander/LANCommander.Servers.WINE). It supports file overlaying using OverlayFS.

---

## Features

- Runs `Tribes.exe -dedicated` from your own install (tested with the community 1.41 release)
- Server name, mission, port, player limit, join and admin passwords are environment variables, written into a generated config script
- Runs under Xvfb, since `Tribes.exe` crashes without a window system
- The server console (`console.log`) goes to `docker logs`
- Supports file overlaying using OverlayFS (no file copying required)

## Docker Compose Example

```yaml
services:
  tribes:
    image: lancommander/tribes:latest
    container_name: tribes

    ports:
      - "28001:28001/udp"

    volumes:
      - ./config:/config

    environment:
      TRIBES_MISSION: "Raindance"
      TRIBES_SERVER_NAME: "My Tribes Server"
      TRIBES_ADMIN_PASSWORD: "secret"

    user: root
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

The in-game LAN browser finds servers by broadcast. That needs the container on the LAN itself (macvlan/ipvlan, or `network_mode: host`); with port mapping, clients join by IP.

---

## Game Files

Tribes has no official server download. Provide a game install, preferably the community **1.40/1.41** release (clients must run the same version):

- copy the game folder (the one containing `Tribes.exe` and `base/`) to `config/Server/`, **or**
- set `TRIBES_ARCHIVE_URL` to a zip of that folder, e.g. a LANCommander archive. It is downloaded and extracted on first start, if `Server/Tribes.exe` doesn't exist yet.

## Directory Layout (Host)

```text
.
└── config/
    ├── Server/            # Tribes install (Tribes.exe, base/, config/ ...)
    ├── Overlay/           # Your files, layered on top of Server/ (config/Server/*.cs, console.log, logs and temp files land here)
    ├── Merged/            # Overlayfs merged view (auto-created, the server runs here)
    ├── wineprefix/        # Wine prefix (auto-created)
    └── Scripts/
        └── Hooks/         # PowerShell scripts run at container lifecycle hooks
```

---

## Environment Variables

These are in addition to the [WINE image's variables](https://github.com/LANCommander/LANCommander.Servers.WINE#environment).
The `TRIBES_*` server settings are written to `config/lancommander.cs` on every start, which the game runs (`+exec`) after its own `config/Server/ServerPrefs.cs`. Settings left empty are not touched, so you can set them in `ServerPrefs.cs` instead.

| Variable | Description | Default |
|----------|-------------|---------|
| `TRIBES_MISSION` | Mission to start (`-dedicated <mission>`); the game type comes from the mission. Empty uses the last mission played (`$pref::lastMission`) | `Raindance` |
| `TRIBES_MOD` | Script mod folder(s) to load with `-mod`, separated by spaces or commas, in load order | |
| `TRIBES_PORT` | Game port (`$Server::Port`) | `28001` |
| `TRIBES_SERVER_NAME` | `$Server::HostName` | `Tribes Server` |
| `TRIBES_SERVER_INFO` | `$Server::Info`, shown in the server info dialog | |
| `TRIBES_MOTD` | `$Server::JoinMOTD`, shown on join | |
| `TRIBES_MAX_PLAYERS` | `$Server::MaxPlayers` | `32` |
| `TRIBES_PASSWORD` | Join password (`$Server::Password`) | |
| `TRIBES_ADMIN_PASSWORD` | Owner Admin password (1.40/1.41 admin scripts) | |
| `TRIBES_TIME_LIMIT` | Minutes per mission (`$Server::timeLimit`) | |
| `TRIBES_TEAM_DAMAGE` | `$Server::TeamDamageScale`: `0` off, `1` on | |
| `TRIBES_PUBLIC` | `$Server::HostPublicGame`: `true` sends heartbeats to the master servers | `false` |
| `TRIBES_ARCHIVE_URL` | Zip of the game folder, used if `Server/Tribes.exe` is missing | |
| `WINE_XVFB` | Must stay on: without a display `Tribes.exe` crashes | `true` |
| `START_EXE` | Launcher | `/usr/local/bin/tribes-server` |
| `START_ARGS` | Added to the `Tribes.exe` command line (before `-dedicated`) | |

See [Documentation/Docker.md](Documentation/Docker.md) for more detail.

---

## Building

The image is built `FROM lancommander/wine:latest` by default. To build against a local base image:

```bash
docker build --build-arg BASE_IMAGE=lancommander/wine:local -t lancommander/tribes:local .
```

---

## License

Starsiege: Tribes and Wine are distributed under their respective licenses.
This repository contains only Docker build logic and helper scripts licensed under MIT.
