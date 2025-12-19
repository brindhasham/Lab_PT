import requests
import sys
def fuzz_loop(target_ip): 
    print(f"--- Fuzzing Started on {target_ip} (Press Ctrl+C to stop) ---")
    for word in sys.stdin:
        word = word.strip()
        url = f"http://{target_ip}/{word}" 
        try:
            res = requests.get(url)
            if res.status_code != 404:
                print(f"[+] Found: {res.status_code} - /{word}")
        except requests.exceptions.RequestException as e:
            print(f"Error connecting: {e}")
            break
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: cat wordlist.txt | python3 fuzzer.py <target_ip>")
        sys.exit()
    ip_input = sys.argv[1]
    fuzz_loop(ip_input)

#Usage: $cat wordlist.txt | python3 fuzzer.py <target_IP>
