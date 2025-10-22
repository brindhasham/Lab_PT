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
### Target machine Linux(Ubuntu 14.04)

---

## Working

### Post-Exploitation

1. **This sceanario is conduction in post-exploitation phase where the attacker has gained remote access and root privileges in the target system**
2. **C2 is a method that cybercriminals use to communicate with compromised devices. In a C&C attack, an attacker uses a server to send commands to — and receive data from — computers compromised, which is known as C2 server.**
3. **The attacker can use the server to perform various malicious actions on the target network, such as data discovery, data exfiltration, malware injection, or denial of service attacks.**
4. **To create a C2 channel, this channel should have following features:**
   - **Pull command from attacker's server using HTTP GET**
   - **Strips headers**
   - **Execute commands**
   - **Capture output**
   - **Send results using HTTP POST with correct content-length**
   - **Use Netcat for portabilty**
   - **Sleeps randomly to simulate real polling behavior**
5. 
