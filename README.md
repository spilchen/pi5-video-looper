# Pi Video Looper

A modernized video looper system for Raspberry Pi 5, forked from [Adafruit's Pi Video Looper](https://github.com/adafruit/pi_video_looper) and updated to use mpv instead of the deprecated omxplayer.

This version has been specifically modified to work with Raspberry Pi OS Bookworm and Raspberry Pi 5, replacing the deprecated omxplayer with the modern mpv video player for better performance and reliability.

## Features

* Automatically plays videos in a loop from a USB drive or local directory
* Supports common video formats (mp4, mkv, avi, mov, etc.)
* Fullscreen playback with seamless looping using mpv
* Simple configuration through an INI file
* On-screen display of playback status (optional)
* Keyboard controls for playback and system control
* GPIO control support for external buttons/switches
* Support for M3U playlists
* Background image display between videos (optional)
* Date/time display between videos (optional)
* USB drive hot-plugging support
* Copy mode for USB drives
* Random playback option

## Requirements

* Raspberry Pi (including Pi 5) running Raspberry Pi OS Bookworm or newer
* Python 3
* mpv video player
* USB drive or local directory with video files

## Installation

1. **(Optional) Enable SSH for Remote Access:**

   If you want to manage your Pi remotely, enable SSH before or after installation:
   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

   You can then access your Pi remotely via:
   ```bash
   ssh username@hostname_or_ip
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/spilchen/pi5-video-looper.git
   cd pi5-video-looper
   ```

3. Run the installer with sudo (it will automatically install for your user):
   ```bash
   sudo ./install.sh
   ```

   The script will detect your username automatically and set up the video looper for your account.

## Usage

1. Copy video files to a USB drive or to `~/video` (in your home directory)
2. Insert the USB drive into the Pi or ensure videos are in the local directory
3. The system will automatically start playing videos in a loop

### Service Management

The video looper runs as a supervised service and will automatically start on boot. You can control it using the following commands:

**Using supervisorctl:**
```bash
# Stop the video looper
sudo supervisorctl stop video_looper

# Start the video looper
sudo supervisorctl start video_looper

# Restart the video looper
sudo supervisorctl restart video_looper

# Check status
sudo supervisorctl status video_looper

# View logs
sudo tail -f /var/log/video_looper.log
```

**Using the included scripts:**
```bash
# Disable autostart on boot
sudo ./disable.sh

# Re-enable autostart on boot
sudo ./enable.sh

# Reload configuration and restart
sudo ./reload.sh
```

### Keyboard Controls

* " " (space bar) - Pause/Resume the video player
* "ESC" - Stop video playback
* "p" - Shut down the Raspberry Pi
* "r" - Restart video playback
* "k" - Skip to the next video
* "j" - Skip to the previous video
* "q" - Quit the video looper

### Configuration

The main configuration file is located at `/boot/video_looper.ini`. You can modify various settings:

* Video player selection (mpv, hello_video, or image_player)
* File source (USB drive or local directory)
* Playback options (random, one-shot, resume)
* Display settings (OSD, background color, background image)
* Control settings (keyboard, GPIO)
* And more...

See the comments in the configuration file for detailed explanations of each setting.

### GPIO Control

You can control the video looper using GPIO pins. Configure the pin mappings in the configuration file:

```ini
gpio_pin_map = "11" : 1, "13": 4, "16": "+2", "18": "-1", "15": "video.mp4"
```

### Playlists

Create M3U playlists to control the order of video playback. Place the playlist file on the USB drive or in the video directory.

Example playlist (playlist.m3u):
```
video1.mp4
video2.mp4
video3.mp4
```

## Troubleshooting

* If videos don't play, check that they are in a supported format
* Ensure proper permissions on the video files and directories
* Check the system logs for any error messages
* Verify that mpv is properly installed

## License

This project is licensed under the GNU GPLv2 license. See LICENSE.txt for details.
