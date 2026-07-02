#!/usr/bin/env python3
"""Serve the browser build (dist/web) — the link you send people.
    python3 server/serve-web.py [port]      (default 8000)
Adds the cross-origin-isolation headers a threaded Godot web build needs (harmless
for the current no-threads build), the right .wasm mime type, and no-store caching
so players always get your latest build on refresh.
"""
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dist", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def __init__(self, *a, **kw):
        super().__init__(*a, directory=ROOT, **kw)


if __name__ == "__main__":
    if not os.path.isfile(os.path.join(ROOT, "index.html")):
        sys.exit("dist/web/index.html not found — run ./server/build-web.sh first")
    print(f"serving dist/web on http://0.0.0.0:{PORT}  (Ctrl-C stops)")
    print("windows browser on this machine: use the WSL IP if localhost doesn't reach WSL")
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
