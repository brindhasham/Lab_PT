#!/usr/bin/env python3
import http.server
import socketserver
import os
from datetime import datetime

C2_DIR = os.path.expanduser("~/c2_sim/c2_data") #to store commands.txt and results.txt, I created this directory to store results dynamically
os.makedirs(C2_DIR, exist_ok=True)
COMMANDS = os.path.join(C2_DIR, "commands.txt")
RESULTS  = os.path.join(C2_DIR, "results.txt")

# ensure files exist
open(COMMANDS, "a").close()
open(RESULTS, "a").close()

PORT = 8000

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/commands.txt":
            try:
                with open(COMMANDS, "rb") as f:
                    data = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
            except Exception as e:
                self.send_error(500, "Server error")
        else:
            self.send_error(404, "Not found")

    def do_POST(self):
        if self.path == "/results.txt":
            try:
                length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(length) if length else b""
                ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
                # append to results with timestamp
                with open(RESULTS, "ab") as f:
                    f.write(b"[" + ts.encode() + b"] ")
                    f.write(body)
                    f.write(b"\n")
                # respond
                resp = b"Received\n"
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(resp)))
                self.end_headers()
                self.wfile.write(resp)
            except Exception as e:
                self.send_error(500, "Server error")
        else:
            self.send_error(404, "Not found")

    # quiet logging
    def log_message(self, format, *args):
        return

if __name__ == "__main__":
    print(f"Serving C2 on port {PORT}, data dir: {C2_DIR}")
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Shutting down")
            httpd.server_close()
