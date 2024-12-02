#!/bin/bash

# Exit jika terjadi error
set -e

# Langkah 1: Meminta input username untuk PS1, dengan fallback ke "root" jika tidak diinput
CUSTOM_USERNAME=${CUSTOM_USERNAME:-root}  # Gunakan variabel lingkungan CUSTOM_USERNAME jika ada

echo "Please enter your custom username for root (default: root):"
read -p "Username [$CUSTOM_USERNAME]: " USER_INPUT

# Jika USER_INPUT kosong, gunakan CUSTOM_USERNAME
if [[ -z "$USER_INPUT" ]]; then
    CUSTOM_USERNAME=$CUSTOM_USERNAME
else
    CUSTOM_USERNAME=$USER_INPUT
fi

echo "Using username: $CUSTOM_USERNAME"

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

# Terapkan perubahan ~/.bashrc dengan source untuk memastikan perubahan langsung diterapkan
echo "Applying changes to .bashrc..."
source "$HOME/.bashrc"  # Pastikan .bashrc dimuat ulang setelah perubahan
echo "PATH and PS1 configured successfully."

# Langkah 7: Generate konfigurasi JupyterLab
echo "Generating JupyterLab configuration..."
jupyter-lab --generate-config

# Set the password and generate the hash
echo "Setting JupyterLab password..."
jupyter-lab password

# Read the hashed password from jupyter_server_config.json
echo "Reading the hashed password from jupyter_server_config.json..."
JUPYTER_PASSWORD_HASH=$(sudo cat ~/.jupyter/jupyter_server_config.json | grep -oP '(?<=hashed_password": ")[^"]*')

# Langkah 9: Konfigurasi JupyterLab server
CONFIG_PATH="$HOME/.jupyter/jupyter_lab_config.py"
cat <<EOT > "$CONFIG_PATH"
c.ServerApp.ip = '$VPS_IP'
c.ServerApp.open_browser = False
c.ServerApp.password = '$JUPYTER_PASSWORD_HASH'
c.ServerApp.port = 8888
c.ContentsManager.allow_hidden = True
c.TerminalInteractiveShell.shell = 'bash'
EOT

echo "Server configuration saved in $CONFIG_PATH"

# Langkah 10: Membuat systemd service untuk JupyterLab (tidak dijalankan otomatis, hanya disimpan)
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

# Langkah 11: Jalankan JupyterLab dalam sesi screen
echo "Starting JupyterLab in a screen session..."
screen -dmS jupy bash -c "jupyter-lab --allow-root"

# Langkah 12: Informasi akhir
echo "Installation complete!"
echo "JupyterLab is running on: http://$VPS_IP:8888"
echo "Your PS1 is set to: root@$CUSTOM_USERNAME"
echo "Your password is saved in $CONFIG_PATH."
echo "To reattach to the screen session, use: screen -r jupy"

# Apply the changes to .bashrc again
source "$HOME/.bashrc"  # This will apply the PS1 changes one more time
