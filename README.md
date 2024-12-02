# JupyterLab Installation Guide on Linux Server
<table style="width: 100%; text-align: center;">
  <tr>
    <td>
<img src="https://github.com/ichinur/install-jupyterlab/blob/main/Screenshot%202024-12-01%20221634.png" alt="JUPYLABS" width="600"/>
   </td>
  </tr>
</table>
The following steps will help you install and configure JupyterLab on a Linux server.

# AUTO INSTALLER
```bash
curl -sSL https://raw.githubusercontent.com/ichinur/install-jupyterlab/refs/heads/main/jupy.sh -o jupy.sh
bash jupy.sh
```


# MANUAL INSTALLER
### 1. Pip and JupyterLab Installation
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip
```
```bash
pip install --user jupyterlab --no-deps
```
### 2. Set path
```bash
sudo nano ~/.bashrc
```
### Fill the ~/.bashrc file with the following:
> **Note:** replace PS1 root@`yourusername`:
```bash
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# History settings
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Check the window size after each command
shopt -s checkwinsize

# Make `less` more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Custom prompt for root and non-root users
if [ "$USER" = "root" ]; then
PS1='\[\e[1;32m\]root@yourusername\[\e[0m\]:\w\$ '
else
    PS1='\u@\h:\w\$ '
fi

# Set the terminal title for xterm-like terminals
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable color support for `ls` and add useful aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

    # Colorize grep
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Include custom aliases if the file exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Memastikan shell selalu bash pada setiap sesi terminal
if [ -z "$PS1" ]; then
    exec /bin/bash
fi

# Export PATH (adjusted for common directories)
export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:/usr/bin:/bin

```
### Apply changes and test
```bash
source ~/.bashrc
```
```bash
jupyter-lab --allow-root
```
### 3. JupyterLab Configuration
```bash
jupyter-lab --generate-config
```
> **Output:** `Writing default config to: /root/.jupyter/jupyter_lab_config.py`
```bash
jupyter-lab password
```
> **Output:**
> 
> Enter password:  
> Verify password:  
> [JupyterPasswordApp] Wrote hashed password to `/root/.jupyter/jupyter_server_config.json`


### Server config Configuration
```bash
sudo cat ~/.jupyter/jupyter_server_config.json
```
> **Note:** Save and note `argon2:<hash-password>`

```bash
sudo nano ~/.jupyter/jupyter_lab_config.py
```
### Fill the file with:
```bash
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.open_browser = False
c.ServerApp.password = 'argon2:<hash-password>'
c.ServerApp.port = 8888
c.ContentsManager.allow_hidden = True
c.TerminalInteractiveShell.shell = 'bash'
```
> **Note:** fill `ServerApp.ip = ""` to your VPS IP, and fill `ServerApp.password = ""` that you noted earlier.

### 4. Creating a Service for JupyterLab
```bash
sudo nano /etc/systemd/system/jupyter-lab.service
```
### Fill the file with:
```bash
[Unit]
Description=Jupyter Lab
[Service]
Type=simple
PIDFile=/run/jupyter.pid
WorkingDirectory=/root/
ExecStart=/root/.local/bin/jupyter-lab --config=/root/.jupyter/jupyter_lab_config.py --allow-root
User=root
Group=root
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
```
### Reload daemon, enable the service, and run JupyterLab with screen session.
```
sudo systemctl daemon-reload
```
```
sudo systemctl enable jupyter-lab.service
```
```
screen -S jupy
```
```
jupyter-lab --allow-root
```
## To exit a screen session:
CTRL + A + D
