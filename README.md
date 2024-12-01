

# Panduan Instalasi JupyterLab di Server Linux
<div style="text-align: center;">
<img src="https://github.com/ichinur/install-jupyterlab/blob/main/Screenshot%202024-12-01%20221634.png" alt="JUPYLABS" width="400"/>
</div>
Langkah-langkah berikut akan membantu Anda menginstal dan mengonfigurasi JupyterLab di server Linux.

## 1. Instalasi Pip dan JupyterLab
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip
```
```bash
pip install --user jupyterlab
```
## 2. Set Path Lokal ke User
```bash
sudo nano ~/.bashrc
```
## Isi file ~/.bashrc dengan yang berikut :
Note :  ganti PS1 root@"masukinusermu":
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
PS1='\[\e[1;32m\]root@masukkanusermu\[\e[0m\]:\w\$ '
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
## Terapkan perubahan dan uji
```bash
source ~/.bashrc
```
```bash
jupyter-lab --allow-root
```
## 3. Konfigurasi JupyterLab
```bash
jupyter-lab --generate-config
```
## Output: Writing default config to: /home/<user>/.jupyter/jupyter_lab_config.py
```bash
jupyter-lab password
```
Output:
Enter password: 
Verify password: 
[JupyterPasswordApp] Wrote hashed password to /home/<user>/.jupyter/jupyter_server_config.json

## Setup jupy config 
```bash
sudo cat ~/.jupyter/jupyter_server_config.json
```
Note : lalu catat "argon2:<hash-password>"
```bash
sudo nano ~/.jupyter/jupyter_lab_config.py
```
## Isi file dengan: 
```bash
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.open_browser = False
c.ServerApp.password = 'argon2:<hash-password>'
c.ServerApp.port = 8888
c.ContentsManager.allow_hidden = True
c.TerminalInteractiveShell.shell = 'bash'
```
ganti ServerApp.ip ke ip vps mu, masukan ServerApp.password yang tadi kamu catat

## 4. Membuat Service untuk JupyterLab
```bash
sudo nano /etc/systemd/system/jupyter-lab.service
```
## Isi file dengan:
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
## Reload daemon, aktifkan service, dan jalankan JupyterLab
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
## Untuk keluar dari sesi screen:
CTRL + A + D
