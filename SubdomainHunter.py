import sys
import requests
if len(sys.argv) < 3:
    print("Usage: python3 hunter.py <target_ip> <wordlist_file>")
    sys.exit()
target_ip = sys.argv[1]
wordlist_file = sys.argv[2]
try:
    with open(wordlist_file, "r") as f:
        for line in f:
            word = line.strip()
            url = f"http://{target_ip}/{word}"
            response = requests.get(url)
            if response.status_code != 404:
                print(f"[+] Found: {response.status_code} - /{word}")
except FileNotFoundError:
    print(f"Error: The file '{wordlist_file}' was not found.")
except requests.exceptions.RequestException as e:
    print(f"Error connecting: {e}")
