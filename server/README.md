# Project Rift — dedicated server (R2)

The server is a **headless Godot running the same repo** — one source of truth: the
identical pure `CombatCore` that the client and the balance sims run. It relays
tick-stamped inputs (deterministic lockstep) and paces the 30 Hz clock; bandwidth is
~30 tiny JSON frames/second. Empty seats play as the AI raiders; a disconnected
player's seat is taken over by AI mid-fight without a hitch.

## Run it on this machine (dev loop)

```sh
./server/serve-local.sh            # ws://127.0.0.1:9077
```

Then in the game: THE RIFT → PLAY ONLINE → server `ws://127.0.0.1:9077` → CONNECT.
Two windows on one box is a real co-op session (the client remembers the address).

## Run it in Docker (the box-agnostic way)

```sh
docker compose -f server/docker-compose.yml up -d --build
docker logs -f rift-server
```

## LAN party

Run either of the above, find your LAN IP (`ip addr`), friends connect to
`ws://192.168.x.x:9077`. (Windows/WSL2: forward the port with
`netsh interface portproxy` or run the server on the Windows side.)

## Move it to a VPS (OVH or anything) — three moves

```sh
rsync -a --exclude .godot ./ vps:~/rift/     # 1. copy the repo (or git clone)
ssh vps "cd rift && docker compose -f server/docker-compose.yml up -d --build"  # 2. same file, unchanged
# 3. everyone points the client at ws://<vps-ip>:9077
```

Open TCP 9077 in the VPS firewall. That's the whole migration — the compose file is
identical everywhere, and the client's server field + `--server=ws://...` flag are
the only knobs.

## Browser builds / wss://

An https-served WASM client may only open `wss://`. Two easy fronts:
- **Cloudflare Tunnel** (free, zero open ports): uncomment the `cloudflared` service
  in the compose file, set `CF_TUNNEL_TOKEN`, point the tunnel at
  `http://rift-server:9077` → clients use `wss://your-tunnel-host`.
- **Caddy** on the VPS: `reverse_proxy rift.example.com { to rift-server:9077 }` —
  Caddy auto-TLS handles the rest.

Native/desktop clients are fine with plain `ws://`.

## Browser build — "send a link" (R2.5)

```sh
./server/build-web.sh              # exports the WASM client to dist/web (one command)
python3 server/serve-web.py 8000   # serves it (no-cache: players get your latest on refresh)
./server/serve-local.sh            # the game server, as usual
```

Players open `http://<host>:8000` — the game boots in the browser and its PLAY ONLINE
screen **defaults to the page's own host** (`ws://<host>:9077`), so a sent link just
works when one box serves both. Iterating = edit game → `build-web.sh` → players
refresh. One-time setup already done on this machine: Godot 4.7 web export templates
in `~/.local/share/godot/export_templates/4.7.stable/` (build is `thread_support=false`
so any static host works — itch.io, nginx, this python script).

WSL note: from the Windows browser use the WSL IP (`ip addr show eth0`), not
localhost — this WSL runs NAT mode. Same for native Windows clients
(`play-windows.bat`) connecting to a WSL-hosted game server.

**Secure context (the gotcha):** Godot web builds only boot on `https://` pages or
`localhost` — a plain `http://<ip>:8000` shows "Secure Context" and refuses. Two outs:
- **Local/LAN via Windows localhost:** run `server/forward-ports.ps1` once per boot in
  an *admin* PowerShell (portproxies 8000+9077 from Windows localhost → the WSL IP).
  Then the page is `http://localhost:8000` and the server field `ws://localhost:9077`.
- **Public https links, zero config:** `./server/tunnel.sh` (Cloudflare quick tunnels,
  no account; `tools/cloudflared` is checked in). It prints TWO urls: the PAGE link
  you send people, and the `wss://…` address they paste into PLAY ONLINE's server
  field (the auto-default points at the page host, which is a different tunnel —
  paste the wss one). Tunnels live while the script runs; URLs change each launch —
  a named Cloudflare tunnel or a VPS with Caddy gives you stable ones later.

## Windows (no WSL) quickstart

Repo ships the native engine: `tools/windows/Godot_v4.7*.exe` (same 4.7-stable build
hash as the Linux one — cross-OS lockstep verified: Windows client + Linux client +
WSL server finished a full fight on the identical checksum).
- `play-windows.bat` — double-click to play (twice for two windows).
- `serve-windows.bat` — run the game server on Windows (then everything is
  `ws://127.0.0.1:9077`, no WSL networking involved).

## Protocol notes

- Version handshake (`NetProtocol.VERSION`) rejects mismatched builds — keep server
  and clients on the same checkout.
- Rooms are keyed by code (default `RIFT`); 4 seats; first joiner hosts and PULLs.
- Checksums ride every 30th frame **as strings** (63-bit ints don't survive JSON
  floats — learned the hard way); a mismatch aborts the fight loudly rather than
  letting replicas drift.
- Fast soak test: `--timescale=5` on `server_main.gd`, or run
  `godot --headless --path godot --script res://sim/net_smoke.gd` for the full
  automated two-client + AI-takeover end-to-end.
