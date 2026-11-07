# syntax=docker/dockerfile:1.7

# Override to build against a locally built base, e.g. lancommander/wine:local
ARG BASE_IMAGE=lancommander/wine:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="Starsiege: Tribes Game Server" \
      org.opencontainers.image.description="Dedicated server for Starsiege: Tribes, running the Windows game's -dedicated mode under Wine" \
      app.lancommander.server.kind="game" \
      app.lancommander.server.game.title="Starsiege: Tribes" \
      app.lancommander.server.external-id.hq="e1c7dad7-2361-4986-afe6-101af8cc4a26" \
      app.lancommander.server.external-id.igdb="881"

# ----------------------------
# Server settings
#   - The game files are not downloaded; put a Tribes install (1.40/1.41 recommended) in
#     /config/Server, or set TRIBES_ARCHIVE_URL to a zip of one. Server/ is the folder that
#     contains Tribes.exe and base/
#   - The TRIBES_* settings below are written into config/lancommander.cs on every start and
#     run with +exec, after the game's own config/Server/ServerPrefs.cs (empty settings are left
#     alone)
#   - Tribes.exe crashes without a window system, so the server runs under Xvfb
# ----------------------------
ENV TRIBES_ARCHIVE_URL="" \
    TRIBES_MISSION="Raindance" \
    TRIBES_MOD="" \
    TRIBES_PORT="28001" \
    TRIBES_SERVER_NAME="Tribes Server" \
    TRIBES_SERVER_INFO="" \
    TRIBES_MOTD="" \
    TRIBES_MAX_PLAYERS="32" \
    TRIBES_PASSWORD="" \
    TRIBES_ADMIN_PASSWORD="" \
    TRIBES_TIME_LIMIT="" \
    TRIBES_TEAM_DAMAGE="" \
    TRIBES_PUBLIC="false" \
    WINE_XVFB="true" \
    START_EXE="/usr/local/bin/tribes-server" \
    START_ARGS=""

COPY Scripts/tribes-server /usr/local/bin/tribes-server
RUN chmod +x /usr/local/bin/tribes-server

COPY Hooks/ "${BASE_HOOKS}/"

# 28001/udp: game, server queries and LAN browser (TRIBES_PORT)
EXPOSE 28001/udp

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]
