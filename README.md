# Panduan Instalasi JupyterLab di Server Linux

Langkah-langkah berikut akan membantu Anda menginstal dan mengonfigurasi JupyterLab di server Linux.

```bash
# 1. Instalasi Pip dan JupyterLab
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip
```
```bash
pip install --user jupyterlab
```
# 2. Set Path Lokal ke User
```bash
sudo nano ~/.bashrc
```
# Isi file ~/.bashrc dengan yang berikut:
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
    PS1='\[\e[1;32m\]root@<username>\[\e[0m\]:\w\$ '
else
    PS1='\u@\h:\w\$ '
fi
# Export PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:/usr/bin:/bin
```
# Terapkan perubahan dan uji
```bash
source ~/.bashrc
```
```bash
jupyter-lab --allow-root
```
# 3. Konfigurasi JupyterLab
```bash
jupyter-lab --generate-config
```
# Output: Writing default config to: /home/<user>/.jupyter/jupyter_lab_config.py
```bash
jupyter-lab password
```
# Output: Masukkan dan verifikasi password, lalu catat hashed_password di ~/.jupyter/jupyter_server_config.json
```bash
sudo nano ~/.jupyter/jupyter_lab_config.py
```
# Isi file dengan:
```bash
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.open_browser = False
c.ServerApp.password = 'argon2:<hash-password>'
c.ServerApp.port = 8888
c.ContentsManager.allow_hidden = True
c.TerminalInteractiveShell.shell = 'bash'
```
# 4. Membuat Service untuk JupyterLab
```bash
sudo nano /etc/systemd/system/jupyter-lab.service
```
# Isi file dengan:
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
# Reload daemon, aktifkan service, dan jalankan JupyterLab
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
# Untuk keluar dari sesi screen:
CTRL + A + D

# Periksa apakah JupyterLab berjalan
ss -antpl | grep jupyter
