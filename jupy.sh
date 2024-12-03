#!/bin/bash

set -e

CUSTOM_USERNAME=${CUSTOM_USERNAME:-root}

echo "Please enter your custom username for root :"
read -p "Username [$CUSTOM_USERNAME]: " USER_INPUT

if [[ -z "$USER_INPUT" ]]; then
    CUSTOM_USERNAME=$CUSTOM_USERNAME
else
    CUSTOM_USERNAME=$USER_INPUT
fi

echo "Using username: $CUSTOM_USERNAME"

echo "Please enter your VPS IP address (e.g., 222.413.123.31):"
read -p "VPS IP: " VPS_IP

if [[ -z "$VPS_IP" ]]; then
    echo "Error: VPS IP cannot be empty."
    exit 1
fi

echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "Installing pip..."
sudo apt install -y python3-pip

echo "Installing JupyterLab..."
pip install --user jupyterlab

echo "Configuring PATH and PS1 in .bashrc..."
BASHRC_PATH="$HOME/.bashrc"

if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$BASHRC_PATH"; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$BASHRC_PATH"
fi

if ! grep -q "export PATH=\$PATH:/usr/bin:/bin" "$BASHRC_PATH"; then
    echo 'export PATH=$PATH:/usr/bin:/bin' >> "$BASHRC_PATH"
fi

# Update PS1 configuration for custom prompt
sed -i '/# Custom prompt for root and non-root users/,/# Set the terminal title for xterm-like terminals/d' "$BASHRC_PATH"
cat <<EOT >> "$BASHRC_PATH"

# Custom prompt for root and non-root users
if [ "\$USER" = "root" ]; then
    PS1='\\[\\e[1;32m\\]root@$CUSTOM_USERNAME\\[\\e[0m\\]:\\w\\$ '
else
    PS1='\\u@\\h:\\w\\$ '
fi
EOT

echo "Applying changes to .bashrc..."
source ~/.bashrc
echo "PATH and PS1 configured successfully."

echo "Generating JupyterLab configuration..."
jupyter-lab --generate-config

jupyter-lab password

echo "Reading the hashed password from jupyter_server_config.json..."
JUPYTER_PASSWORD_HASH=$(sudo cat ~/.jupyter/jupyter_server_config.json | grep -oP '(?<=hashed_password": ")[^"]*')

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

sudo systemctl daemon-reload
sudo systemctl enable jupyter-lab.service

echo "Starting JupyterLab in a screen session..."
screen -dmS jupy bash -c "/root/.local/bin/jupyter-lab --allow-root"

echo "Installation complete!"
echo "JupyterLab is running on: http://$VPS_IP:8888"
echo "Your PS1 is set to: root@$CUSTOM_USERNAME"
echo "Your password is saved in $CONFIG_PATH."
echo "To reattach to the screen session, use: screen -r jupy"

source ~/.bashrc
