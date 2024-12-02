#!/bin/bash

# Exit if any command fails
set -e

# Step 1: Request custom username input (default: root)
CUSTOM_USERNAME=${CUSTOM_USERNAME:-root}
echo "Please enter your custom username for root (default: root):"
read -p "Username [$CUSTOM_USERNAME]: " USER_INPUT

# Use the custom username if provided
if [[ -z "$USER_INPUT" ]]; then
    CUSTOM_USERNAME=$CUSTOM_USERNAME
else
    CUSTOM_USERNAME=$USER_INPUT
fi

echo "Using username: $CUSTOM_USERNAME"

# Step 2: Request VPS IP address
echo "Please enter your VPS IP address (e.g., 192.168.1.1):"
read -p "VPS IP: " VPS_IP

if [[ -z "$VPS_IP" ]]; then
    echo "Error: VPS IP cannot be empty."
    exit 1
fi

# Step 3: Update and upgrade system
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Step 4: Install pip
echo "Installing pip..."
sudo apt install -y python3-pip

# Step 5: Install JupyterLab
echo "Installing JupyterLab..."
pip install --user jupyterlab

# Step 6: Configure PATH and PS1 in .bashrc
echo "Configuring PATH and PS1 in .bashrc..."
BASHRC_PATH="$HOME/.bashrc"

# Add PATH if it doesn't exist
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$BASHRC_PATH"; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$BASHRC_PATH"
fi

# Adjust PS1 with custom username
sed -i '/# Custom prompt for root and non-root users/,/# Set the terminal title for xterm-like terminals/d' "$BASHRC_PATH"
cat <<EOT >> "$BASHRC_PATH"

# Custom prompt for root and non-root users
if [ "\$USER" = "root" ]; then
    PS1='\\[\\e[1;32m\\]root@$CUSTOM_USERNAME\\[\\e[0m\\]:\\w\\$ '
else
    PS1='\\u@\\h:\\w\\$ '
fi
EOT

# Apply changes to .bashrc
echo "Applying changes to .bashrc..."
source ~/.bashrc

# Step 7: Generate JupyterLab configuration
echo "Generating JupyterLab configuration..."
jupyter-lab --generate-config

# Step 8: Set JupyterLab password and hash it
echo "Please enter your password for JupyterLab:"
read -s JUPYTER_PASSWORD
echo "Verifying password..."
read -s JUPYTER_PASSWORD_VERIFY

if [ "$JUPYTER_PASSWORD" != "$JUPYTER_PASSWORD_VERIFY" ]; then
    echo "Error: Passwords do not match!"
    exit 1
fi

echo "Setting JupyterLab password..."
jupyter-lab password

# Step 9: Read the hashed password from jupyter_server_config.json
echo "Reading the hashed password from jupyter_server_config.json..."
JUPYTER_PASSWORD_HASH=$(sudo cat ~/.jupyter/jupyter_server_config.json | grep -oP '(?<=hashed_password": ")[^"]*')

# Step 10: Configure JupyterLab server settings
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

# Step 11: Set correct file permissions
echo "Setting correct permissions for config files..."
sudo chmod 644 ~/.jupyter/jupyter_server_config.json
sudo chmod 644 ~/.jupyter/jupyter_lab_config.py

# Step 12: Create systemd service for JupyterLab
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

# Step 13: Start JupyterLab in a screen session
echo "Starting JupyterLab in a screen session..."
screen -dmS jupy bash -c "jupyter-lab --allow-root"

# Step 14: Final information
echo "Installation complete!"
echo "JupyterLab is running on: http://$VPS_IP:8888"
echo "Your PS1 is set to: root@$CUSTOM_USERNAME"
echo "To reattach to the screen session, use: screen -r jupy"
