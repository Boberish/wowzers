# Project Rift — dedicated server image (R2).
# Headless Godot + the game project; the server IS the game code (one source of truth).
# Build from the REPO ROOT:  docker build -f server/Dockerfile -t rift-server .
FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7-stable
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates unzip wget libfontconfig1 \
    && wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip -O /tmp/godot.zip \
    && unzip -q /tmp/godot.zip -d /tmp \
    && mv /tmp/Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -rf /tmp/godot.zip /var/lib/apt/lists/*

WORKDIR /app
COPY godot/ /app/project/

# build the global class cache once so --script runs resolve class_names
RUN godot --headless --path /app/project --import || true

EXPOSE 9077
ENV PORT=9077
CMD godot --headless --path /app/project --script res://net/server_main.gd -- --port=${PORT}
