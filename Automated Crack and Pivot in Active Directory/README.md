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
- **Windows Server Domain controller with Active Directory configured(assined IP in lab= 10.10.10.131)**
- **Windows client joined to the domain.(assined IP in lab= 10.10.10.130)**
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
  


