# Automated Command-and-Control (C2) Simulation Tool

**This is a lightweight Bash-and-Python-based Command-and-Control (C2) simulation tool for remote command execution, data exfiltration, and to maintain stealthy persistence on a target.**

---

## Features

- **Post exploitation, agent added as a cronjob, auto-starts on system reboot which exfiltrates results using HTTP GET/POST.**
- **Python based C2 HTTP server is created on the attacker side for communication with the target**
- **Agent reaches to the attacker server for every 30-60 seconds to pull commands from commands.txt**
- **The results are stores in results.txt with timestamps**
- **Agent logs activity to  for forensic traceability.**

---

