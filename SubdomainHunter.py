import sys
import requests
if len(sys.argv) < 3:
    print("Usage: python3 hunter.py <target_ip> <wordlist_file>")
    sys.exit()
target_ip = sys.argv[1]
wordlist_file = sys.argv[2]
print(f"[*] Scanning {target_ip} using {wordlist_file}...")
try:
    with open(wordlist_file, "r") as f:
        for line in f:
            word = line.strip()
            if not word: continue 
            url = f"http://{target_ip}/{word}"
            response = requests.get(url, timeout=3, allow_redirects=False)
            if response.status_code != 404:
                print(f"[+] Found: {response.status_code} - /{word}")
except FileNotFoundError:
    print(f"Error: The file '{wordlist_file}' was not found.")
except requests.exceptions.RequestException:
    pass 
except KeyboardInterrupt:
    print("\n[!] User stopped the scan.")
    sys.exit()
