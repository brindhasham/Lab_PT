# Automated Command-and-Control (C2) Simulation Tool

**This is a lightweight Bash-and-Python-based Command-and-Control (C2) simulation tool for remote command execution, data exfiltration, and to maintain stealthy persistence on a target.**

---

## Features

- **Post exploitation, agent added as a cronjob, auto-starts on system reboot which exfiltrates results using HTTP GET/POST.**
- **Python based C2 HTTP server is created on the attacker side for communication with the target**
- **Agent reaches to the attacker server for every 30-60 seconds to pull commands from commands.txt**
- **The results are stores in results.txt with timestamps**
- **Agent logs activity for forensic traceability.**

---

### Target machine: Linux(Ubuntu 14.04)

---

## Working

### Post-Exploitation

1. **This sceanario is conducted in post-exploitation phase where the attacker has gained remote access and root privileges in the target system**
   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/sessions.png)
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
5. **The [agent.sh](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/agent.sh) with above features is uploaded to the target system**
   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/cron.png)
6. **Now I created a cronfile in the target using shell to via command `echo "@reboot /home/agent.sh &" > mycron`**
7. **To load it into crontab `crontab mycron`**
8. **I can verify it by `crotab -l` to list the added cronjob**
 
   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/crontab.png)
9. **I will make sure cron is running by `sudo systemctl status cron` if not I will use `sudo systemctl start cron`**
10. **Now I made a server on my attacker machine that is compatible with this agent. It has following featurs**
    - **Serves on GET**
    - **Appends POST bodies to with UTC timestamps**
    - **Handles headers, content length, and response codes properly**
    - **Silences noisy logs for stealth and clarity**
    - **Auto-creates the working directory and files**
11. **Now I will grant execute permission to this python script by `chmod +x` [server.py](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/server.py)**
12. **`python3` [server.py](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/server.py)**

     ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/python.png)

13. **When the target reboots, and we loose out initial access to the target system, we now receive responses from the commands we pass to [commands.txt](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/c2_sim/c2_data/commands.txt)**
 
 ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/attacker_server.png)

 ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/commands%20.png)


 
14. **The results will be stored in [results.txt](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/c2_sim/c2_data/results.txt)**

   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/results.png)


15. **The agent logs will be stored under tmp directory as agent_nc.log**
![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Command-and-Control%20(C2)%20Simulation%20Tool/Screensnips/agent_nc_log.png)

---

### This project shows successful establiment of command and control on target
