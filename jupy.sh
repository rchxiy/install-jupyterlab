#!/bin/bash

# Exit if any command fails
set -e

# Step 1: Get the custom username (default is "root")
CUSTOM_USERNAME=${CUSTOM_USERNAME:-root}  # Use CUSTOM_USERNAME variable if provided

echo "Please enter your custom username for root (default: root):"
read -p "Username [$CUSTOM_USERNAME]: " USER_INPUT

if [[ -z "$USER_INPUT" ]]; then
    CUSTOM_USERNAME=$CUSTOM_USERNAME
else
    CUSTOM_USERNAME=$USER_INPUT
fi

echo "Using username: $CUSTOM_USERNAME"

# Step 2: Get the VPS IP address
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

# Step 6: Configure PATH and PS1 in ~/.bashrc
echo "Configuring PATH and PS1 in .bashrc..."
BASHRC_PATH="$HOME/.bashrc"

# Add PATH if not already there
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$BASHRC_PATH"; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$BASHRC_PATH"
fi

# Update PS1 for custom username
sed -i '/# Custom prompt for root and non-root users/,/# Set the terminal title for xterm-like terminals/d' "$BASHRC_PATH"
cat <<EOT >> "$BASHRC_PATH"

# Custom prompt for root and non-root users
if [ "\$USER" = "root" ]; then
    PS1='\\[\\e[1;32m\\]root@$CUSTOM_USERNAME\\[\\e[0m\\]:\\w\\$ '
else
    PS1='\\u@\\h:\\w\\$ '
fi
EOT

# Apply changes to ~/.bashrc
echo "Applying changes to .bashrc..."
source "$HOME/.bashrc"

# Step 7: Generate JupyterLab configuration
echo "Generating JupyterLab configuration..."
jupyter-lab --generate-config

# Step 8: Set and hash JupyterLab password
echo "Please enter your password for JupyterLab:"
read -s JUPYTER_PASSWORD
echo "Verifying password..."
read -s JUPYTER_PASSWORD_VERIFY

if [ "$JUPYTER_PASSWORD" != "$JUPYTER_PASSWORD_VERIFY" ]; then
    echo "Error: Passwords do not match!"
    exit 1
fi

# Hash the password using argon2
JUPYTER_PASSWORD_HASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")

# Step 9: Configure JupyterLab server
CONFIG_PATH="$HOME/.jupyter/jupyter_lab_config.py"
cat <<EOT > "$CONFIG_PATH"
c.ServerApp.ip = '0.0.0.0'  # Allow external access
c.ServerApp.open_browser = False  # Don't open browser automatically
c.ServerApp.password = '$JUPYTER_PASSWORD_HASH'  # Use the hash from jupyter_server_config.json
c.ServerApp.port = 8888  # Set port to 8888
c.ContentsManager.allow_hidden = True  # Allow hidden files
c.TerminalInteractiveShell.shell = 'bash'  # Use bash for terminal
EOT

echo "Server configuration saved in $CONFIG_PATH"

# Step 10: Create systemd service for JupyterLab (does not start automatically, only saved)
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

# Reload systemd daemon to apply the service configuration
sudo systemctl daemon-reload
sudo systemctl enable jupyter-lab.service

# Step 11: Start JupyterLab in a screen session
echo "Starting JupyterLab in a screen session..."
screen -dmS jupy bash -c "jupyter-lab --allow-root"

# Step 12: Final information
echo "Installation complete!"
echo "JupyterLab is running on: http://$VPS_IP:8888"
echo "Your PS1 is set to: root@$CUSTOM_USERNAME"
echo "Your password is saved in $CONFIG_PATH."
echo "To reattach to the screen session, use: screen -r jupy"
