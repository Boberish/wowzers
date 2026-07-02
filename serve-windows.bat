@echo off
rem Project Rift - dedicated server on Windows. Keep this window open while playing.
rem Clients connect to ws://127.0.0.1:9077 (this PC) or ws://YOUR-LAN-IP:9077 (friends).
echo === Project Rift server - close this window to stop ===
"%~dp0tools\windows\Godot_v4.7-stable_win64_console.exe" --headless --path "%~dp0godot" --script res://net/server_main.gd -- --port=9077
pause
