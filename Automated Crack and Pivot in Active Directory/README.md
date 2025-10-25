# Automated Crack and Pivot in Active Directory

**This is an automated NTLMv2 Hash Capture, Cracking, and SMB Pivoting in Active Directory Labs**

## Features

- **Launches Responder, simulates client activity, and captures NTLMv2 hashes with timeout-controlled monitoring**
- **Parses Responder DB/logs, cracks hashes via Hashcat, and extracts credentials from potfile for NT hash computation**
- **Uses Crackmapexec to pivot across AD hosts with cracked credentials, executing commands and logging success/failure per hash**
- **Terminates Responder, clears temp files, and generates timestamped logs to maintain operational hygiene.**
- **Performs, 3 activities consequentially, capture using Responder, Cracks using Hashcat and pivots using crackmapexec**


