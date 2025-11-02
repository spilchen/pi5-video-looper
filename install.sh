#!/bin/sh

# Error out if anything fails.
set -e

# Make sure script is run as root.
if [ "$(id -u)" != "0" ]; then
  echo "Must be run as root with sudo! Try: sudo ./install.sh"
  exit 1
fi

# Make sure we can determine the actual user (must be run with sudo, not as root directly)
if [ -z "$SUDO_USER" ]; then
  echo "Error: Cannot determine the user. Please run with sudo, not as root directly."
  echo "Try: sudo ./install.sh"
  exit 1
fi

echo "Installing for user: $SUDO_USER"

echo "Installing dependencies..."
echo "=========================="
# First update and install system packages
apt update
apt -y install python3 python3-pip python3-venv python3-pygame supervisor mpv ntfs-3g exfat-fuse
apt -y install python3-dev python3-setuptools

# Try to install GPIO packages but don't fail if they're not available
echo "Attempting to install GPIO support (optional)..."
apt -y install python3-rpi.gpio python3-pigpio python3-gpiozero || true
apt -y install raspi-gpio pigpio || true

echo "Installing video_looper program..."
echo "=================================="

# change the directory to the script location
cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# Create required directories
mkdir -p /mnt/usbdrive0
mkdir -p /home/$SUDO_USER/video

# Create group if it doesn't exist and set ownership
groupadd -f $SUDO_USER
usermod -a -G $SUDO_USER $SUDO_USER
usermod -a -G gpio $SUDO_USER || true
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/video

# Create and activate virtual environment
VENV_PATH="/home/$SUDO_USER/video_looper_env"
python3 -m venv $VENV_PATH
chown -R $SUDO_USER:$SUDO_USER $VENV_PATH

# Install packages in virtual environment
su - $SUDO_USER << EOF
cd "$REPO_DIR"
source $VENV_PATH/bin/activate
python3 -m pip install --upgrade pip setuptools wheel
# Try to install with GPIO support, fall back to basic install if it fails
python3 -m pip install ".[gpio]" || python3 -m pip install .
deactivate
EOF

# Create service file for supervisor
# Get the user ID for XDG_RUNTIME_DIR
USER_ID=$(id -u $SUDO_USER)
cat > /etc/supervisor/conf.d/video_looper.conf << EOF
[program:video_looper]
command=$VENV_PATH/bin/python3 -m Adafruit_Video_Looper.video_looper
directory=/home/$SUDO_USER
user=$SUDO_USER
autostart=true
autorestart=true
stdout_logfile=/var/log/video_looper.log
redirect_stderr=true
environment=PYTHONPATH="/usr/lib/python3/dist-packages",XDG_RUNTIME_DIR="/run/user/$USER_ID"
EOF

# Copy configuration file and replace username placeholders
cp ./assets/video_looper.ini /boot/video_looper.ini
sed -i "s|/home/pi|/home/$SUDO_USER|g" /boot/video_looper.ini

echo "Configuring video_looper to run on start..."
echo "==========================================="

# Ensure log file exists and has correct permissions
touch /var/log/video_looper.log
chown $SUDO_USER:$SUDO_USER /var/log/video_looper.log

# Allow video looper user to mount/unmount USB drives without password
cat > /etc/sudoers.d/video_looper << EOF
# Allow video looper user to mount/unmount USB drives
$SUDO_USER ALL=(ALL) NOPASSWD: /bin/mount, /bin/umount, /bin/mkdir, /bin/rm
$SUDO_USER ALL=(ALL) NOPASSWD: /usr/bin/mount, /usr/bin/umount, /usr/bin/mkdir, /usr/bin/rm
EOF
chmod 0440 /etc/sudoers.d/video_looper

# Try to start GPIO daemon but don't fail if it doesn't work
systemctl enable pigpiod || true
systemctl start pigpiod || true

# Make sure supervisor is running
systemctl enable supervisor
systemctl start supervisor

# Tell supervisor to reload config and start the video looper
supervisorctl reread
supervisorctl update
supervisorctl start video_looper

echo "Finished!"
echo ""
echo "Video looper has been installed and started."
echo "To check status: sudo supervisorctl status video_looper"
echo "To view logs: sudo tail -f /var/log/video_looper.log"
