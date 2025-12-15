#!/bin/bash

# Start SDRPlay API service daemon (if not already running)
# This is the userland service that brokers access to SDRPlay hardware
if [ -x /opt/sdrplay_api/sdrplay_apiService ]; then
    echo "Starting SDRPlay API service..."
    /opt/sdrplay_api/sdrplay_apiService &
    sleep 1
fi

SNUM=$(echo $DISPLAY | sed 's/:\([0-9][0-9]*\)/\1/')
xvfb-run -n $SNUM -s "-screen 0 1024x768x24" -f ~/.Xauthority openbox-session &
sleep 1
x11vnc -display $DISPLAY -usepw -forever -quiet &

# Launch GNU Radio Companion
sleep 1
if [ -n "$GRC_DIR" ] && [ -d "$GRC_DIR" ]; then
    GRC_FILES=$(find "$GRC_DIR" -maxdepth 1 -name "*.grc" -type f | sort)
    if [ -n "$GRC_FILES" ]; then
        echo "Opening GRC files from $GRC_DIR:"
        echo "$GRC_FILES"
        gnuradio-companion $GRC_FILES &
    else
        echo "No .grc files found in $GRC_DIR, starting empty"
        gnuradio-companion &
    fi
else
    gnuradio-companion &
fi

# Also launch xterm for command-line access
xterm &

# Launch VLC for RF video streaming
vlc &

# Start noVNC web server (access via browser at http://localhost:6080/vnc.html)
# Bind to 0.0.0.0 for WSL/Docker compatibility
websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5900 &

exec "$@"