#Simple program to find href, input, comments and server fingerprint of a webpage

import requests
from bs4 import BeautifulSoup, Comment

def spider(website):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    }
    try:
        response = requests.get(website, headers=headers, timeout=5)
        print(f"[*]Responsecode {response.status_code}")
        print("-" * 30)
        res_soup = BeautifulSoup(response.text, "html.parser")
        all_links = res_soup.find_all("a")
        print(f"Number of links found in {website} are: {len(all_links)}")
        for link in all_links:
            href_link = link.get("href")
            print(f"Link: {href_link}")
        print("-" * 30)
        inputs = res_soup.find_all("input")
        print(f"The number of inputs fields found in {website}: {len(inputs)} ")
        for item in inputs:
            input_type = item.get("type")
            input_name = item.get("name")
            print(f"Input type: {input_type} \nInput name: {input_name}")
            if input_type == "password":
                fieldname = item.get("name")
                print(f"Sensitive field found: {fieldname}")
        print("-" * 30)
        comments = res_soup.find_all(string= lambda text:isinstance(text, Comment))
        print(f"The total number of Comments found in the {website} is {len(comments)}")
        for c in comments:
            print(f"Hidden Comment: {c.strip()}")
            comment_text = c.lower()
            if "pass" in comment_text or "user" in comment_text or "config" in comment_text:
                print(f"[*] Sensitive comment found: {comment_text}")
        print("-" * 30)
        server = response.headers.get("Server")
        power_by = response.headers.get("X-Powered-By")
        print(f"Server: {server or 'Not Disclosed'}")
        print(f"Powered-By: {power_by or 'Not Disclosed'}")
        if server and "Apache/2.2" in server:
            print("[!!!] ALERT: VULNERABLE SERVER VERSION DETECTED (Apache 2.2 is EOL)")
        if power_by and "PHP/5" in power_by:
            print("[!!!] ALERT: OLD PHP VERSION DETECTED")
    except Exception as e:
        print(f" The error detected is: {e}")

website = input("Enter a website to spider: ")
spider(website)
