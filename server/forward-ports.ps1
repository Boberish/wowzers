# Project Rift — make WSL's game ports reachable as Windows localhost.
# Run ONCE PER BOOT in an *Administrator* PowerShell:
#   powershell -ExecutionPolicy Bypass -File \\wsl.localhost\Ubuntu\home\bill\projects\Wowzers\server\forward-ports.ps1
# Then the browser page is http://localhost:8000 (a secure context — Godot boots)
# and the game server field is ws://localhost:9077.
$wslIp = (wsl hostname -I).Trim().Split(" ")[0]
Write-Host "WSL IP: $wslIp"
foreach ($port in 8000, 9077) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=127.0.0.1 2>$null | Out-Null
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=127.0.0.1 connectport=$port connectaddress=$wslIp
    Write-Host "localhost:$port -> ${wslIp}:$port"
}
netsh interface portproxy show v4tov4
