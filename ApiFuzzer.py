import requests
import sys
def fuzz_loop():
    print("--- Fuzzing Started (Press Ctrl+C to stop) ---")
    for word in sys.stdin:
        word = word.strip()
        url = f"http://10.10.x.x/{word}"
        try:
            res = requests.get(url)
            if res.status_code != 404:
                print(f"[+] Found: {res.status_code} - /{word}")
        except requests.exceptions.RequestException as e:
            print(f"Error connecting: {e}")
            break

if __name__ == "__main__":
    fuzz_loop()
