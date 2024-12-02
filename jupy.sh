#!/bin/bash

# Exit jika terjadi error
set -e

# Langkah 1: Meminta input username untuk PS1, dengan fallback ke "root" jika tidak diinput
echo "Please enter your custom username for root (e.g., root):"
read -p "Username: " CUSTOM_USERNAME

# Jika CUSTOM_USERNAME kosong, set ke 'root'
if [[ -z "$CUSTOM_USERNAME" ]]; then
    CUSTOM_USERNAME="root"
    echo "No username entered. Using default: $CUSTOM_USERNAME"
fi

# Langkah 2: Meminta input IP VPS
echo "Please enter your VPS IP address (e.g., 192.168.1.1):"
read -p "VPS IP: " VPS_IP

if [[ -z "$VPS_IP" ]]; then
    echo "Error: VPS IP cannot be empty."
    exit 1
fi

# Langkah 3: Update dan upgrade sistem
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Langkah 4: Install pip
echo "Installing pip..."
sudo apt install -y python3-pip

# Langkah 5: Install JupyterLab
echo "Installing JupyterLab..."
pip install --user jupyterlab

# Langkah 6: Konfigurasi PATH dan PS1 di ~/.bashrc
echo "Configuring PATH and PS1 in .bashrc..."
BASHRC_PATH="$HOME/.bashrc"

# Menambahkan PATH jika belum ada
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$BASHRC_PATH"; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$BASHRC_PATH"
fi

# Menyesuaikan PS1 dengan input username
sed -i '/# Custom prompt for root and non-root users/,/# Set the terminal title for xterm-like terminals/d' "$BASHRC_PATH"
cat <<EOT >> "$BASHRC_PATH"

# Custom prompt for root and non-root users
if [ "\$USER" = "root" ]; then
    PS1='\\[\\e[1;32m\\]root@$CUSTOM_USERNAME\\[\\e[0m\\]:\\w\\$ '
else
    PS1='\\u@\\h:\\w\\$ '
fi
EOT

# Terapkan perubahan ~/.bashrc
source "$BASHRC_PATH"
echo "PATH and PS1 configured successfully."

# Langkah 7: Generate konfigurasi JupyterLab
echo "Generating JupyterLab configuration..."
jupyter-lab --generate-config

# Langkah 8: Meminta password JupyterLab
echo "Please enter a password for JupyterLab:"
read -s JUPYTER_PASSWORD
echo "Verifying password..."
read -s JUPYTER_PASSWORD_VERIFY

if [ "$JUPYTER_PASSWORD" != "$JUPYTER_PASSWORD_VERIFY" ]; then
    echo "Error: Passwords do not match!"
    exit 1
fi

# Hash password menggunakan Python
HASHED_PASSWORD=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")

# Langkah 9: Membuat file JSON dengan hash password
CONFIG_JSON="$HOME/.jupyter/jupyter_server_config.json"
mkdir -p "$HOME/.jupyter"

cat <<EOT > "$CONFIG_JSON"
{
  "IdentityProvider": {
    "hashed_password": "$HASHED_PASSWORD"
  }
}
EOT

echo "Hash password saved in $CONFIG_JSON"

# Langkah 10: Konfigurasi JupyterLab server
CONFIG_PATH="$HOME/.jupyter/jupyter_lab_config.py"
cat <<EOT > "$CONFIG_PATH"
c.ServerApp.ip = '$VPS_IP'
c.ServerApp.open_browser = False
c.ServerApp.password = '$HASHED_PASSWORD'
c.ServerApp.port = 8888
c.ContentsManager.allow_hidden = True
c.TerminalInteractiveShell.shell = 'bash'
EOT

echo "Server configuration saved in $CONFIG_PATH"

# Langkah 11: Membuat systemd service untuk JupyterLab (tidak dijalankan otomatis, hanya disimpan)
SERVICE_FILE="/etc/systemd/system/jupyter-lab.service"
sudo bash -c "cat <<EOT > $SERVICE_FILE
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
EOT"

# Reload systemd daemon
sudo systemctl daemon-reload
sudo systemctl enable jupyter-lab.service

# Langkah 12: Jalankan JupyterLab dalam sesi screen
echo "Starting JupyterLab in a screen session..."
screen -dmS jupy bash -c "jupyter-lab --allow-root"

# Langkah 13: Informasi akhir
echo "Installation complete!"
echo "JupyterLab is running on: http://$VPS_IP:8888"
echo "Your PS1 is set to: root@$CUSTOM_USERNAME"
echo "Your hashed password (argon2) is saved in $CONFIG_JSON and added to the server configuration."
echo "To reattach to the screen session, use: screen -r jupy"
