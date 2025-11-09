# Automated Crack and Pivot in Active Directory

**This is an automated NTLMv2 Hash Capture, Cracking, and SMB Pivoting in Active Directory Labs**

## Features

- **Launches Responder, simulates client activity, and captures NTLMv2 hashes with timeout-controlled monitoring**
- **Parses Responder DB/logs, cracks hashes via Hashcat, and extracts credentials from potfile for NT hash computation**
- **Uses Crackmapexec to pivot across AD hosts with cracked credentials, executing commands and logging success/failure per hash**
- **Terminates Responder, clears temp files, and generates timestamped logs to maintain operational hygiene.**
- **Performs, 3 activities consequentially, capture using Responder, Cracks using Hashcat and pivots using crackmapexec**

---
### Idea Workflow for the script

![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/Screensnips/Workflow.png)


---

### Machines used:
- **Windows Server Domain controller with Active Directory configured(assigned IP in lab= 10.10.10.131)**
- **Windows client joined to the domain.(assigned IP in lab= 10.10.10.130)**
- **Kali Linux (attacker)**

---

### Idea generation for this project

- **Active Directory (AD) is a directory service developed by Microsoft for managing network resources in Windows domain networks. A domain controller (DC) is a server that runs Active Directory Domain Services (AD DS) and is responsible for authenticating and authorizing users and computers within the network**
- **It authenticates and authorizes users and computers in a Windows domain.**
- **Stores and manages the Active Directory (AD) database, which includes:**
• **User accounts**
• **Group policies**
• **Computer objects**
• **Security identifiers (SIDs)**
• **Responds to Kerberos and NTLM authentication requests**
- **When a Windows machine (including an ADDC) tries to resolve a hostname like , it follows a resolution order:**
  1. 	**DNS — Primary method for resolving names.**
  2. 	**Hosts file**
  3. 	**LLMNR (Link-Local Multicast Name Resolution)**
  4. 	**NBT-NS (NetBIOS Name Service)**
  5. 	**MDNS (Multicast DNS, mostly for Bonjour/Apple-like services)**
- **If DNS fails (e.g., the name doesn’t exist or the server is offline), Windows falls back to LLMNR/NBT-NS/MDNS**
- **By default, even ADDCs have LLMNR and NBT-NS enabled, unless explicitly disabled**
- **My Idea of for this script originates here to exploit this vulnerability where the system is not hardened by the system administrator, which can cause serious issues in real life scenarios**
- **DNS fails → LLMNR/NBT-NS kicks in --->Responder poisons the response --->ADDC sends NTLMv2 auth to Responder**

---

### Setup

- **Firstly, I had installed Windows Server 2019 vm with IP 10.10.10.131**
- **Installed ADDS using Server Manager**
- **Promoted this server to a domain controller with new forest and root domain added**
- **Using Active Directory Users and Computers (ADUC), set up few users and added to few builtin groups**
- **Now as a client, installed new Windows 10 vm with IP 10.10.10.130 and assigned the server's IP as preferred DNS in IPv4 settings and added the domain in System properties for this machine and rebooted to save changes**
- **Now both server and client is setup**

---
  
### Script generation idea

- **As an attacker, I wanted to created a script that would exploit this vulnerability with just simple inputs and generate a robust exploitation outputs**
- **Since I am using Responder, it should run with root privileges, so first the script should check that**
- **Once done, it should setup environment directories and files**
  - **demo_output: folder to carry all the files generated**
  - **lateral_log.txt: file to store captured hashes, cracked NTLMv2 hashes, access logs using crackmapexec and output information using crackmapexec**
  - **cracked_hashes: should contain NT hashes**
  - **hashcat.potfile: this will store cracked hashes and their corresponding plaintext passwords**
  - **hash_type: for debugging purposes.**
  - **responder_logs: folder to save files generated when responder is actively capturing the hashes**
  - **responder_stdout.log: to save or captures of Responder**
  - **responder_copy: foler to copy the Responder installation in our log dir for isolated execution (it will contain Responder.db)**
- **This script should kill any responder process running before**
- **Clear cache and previous logs if any**
- **It should copy and launch responder**
- **Wait for hashes to be captured with timeout atleast with 300s**
- **Once hashes are captured, it should extract from Responder.db using sqllite3 and crack hashes with Hashcat and the potfile will store NetNTLMv2 hashes and their plaintext passwords**
- **Now for NT hash computation, we have potfile with plaintext password, we will convert this plaintext to UTF-16LE using iconv and hash it with MD4 using openssl and extracts the hash value with awk. Note this NT hashes will be stored in cracked_hashes file**
- **We will test the the validity of the NT hash by using Crackmapexec to check the accessibility to the target**
- **If authentication succeeds, then execute custom command using crackmapexec**

### This is the idea workflow for script creation.

**The script can be accessed [here](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/C2P.sh)**


---

## Working

1. **Make sure the client and server are running on the same network as attacker machine**
2. **On attacker machine run this code `sudo ./`[C2P.sh](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/C2P.sh) `eth0 10.10.10.131 /home/kali/testhash.txt` (any custom wordlist can be used, if not added, the script automatically uses rockyou.txt for hashcat)**
3. **On the Windows client, simulate user activity (e.g., accessed a non-existent share: `\\<kali_ip>\fake`).**
4. **The script runs the tools and displays output as follows. Complete output of the test is available [here](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/output.txt)**

5. ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/Screensnips/output1.png)
   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/Screensnips/output2.png)
   ![](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/Screensnips/output3.png)

6. **The output files can here accessed here**
   - [captured_hashes](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/demo_output/captured_hashes.txt)
   - [cracked_hashes](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/demo_output/cracked_hashes.txt)
   - [hash_types](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/demo_output/hash_types.txt)
   - [hashcat.potfile](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/demo_output/hashcat.potfile)
   - [lateral_log.txt](https://github.com/brindhasham/Lab_PT/blob/main/Automated%20Crack%20and%20Pivot%20in%20Active%20Directory/demo_output/lateral_log.txt)
   ### This concludes successful pass the hash attack
