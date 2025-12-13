FROM ubuntu:24.04

# Build arguments for multi-arch support
# TARGETARCH is automatically set by Docker buildx (amd64, arm64)
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Base packages + GNU Radio + build dependencies
# =============================================================================
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    dbus-x11 \
    dos2unix \
    file \
    gir1.2-gtk-3.0 \
    git \
    gnuradio \
    gnuradio-dev \
    libgtk-3-0 \
    libspdlog-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    novnc \
    openbox \
    pkg-config \
    python3-gi-cairo \
    python3-xdg \
    udev \
    usbutils \
    vlc \
    websockify \
    x11vnc \
    xterm \
    xvfb \
    xz-utils

# =============================================================================
# Install SDRPlay API 3.15 (architecture-aware)
# Download official installer and extract using --tar flag for non-interactive install
# =============================================================================
ADD https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.15.2.run /tmp/SDRplay.run
RUN chmod +x /tmp/SDRplay.run && \
    cd /tmp && \
    ./SDRplay.run --tar -xvf && \
    # Detect architecture and set the correct library directory
    # Note: SDRPlay uses 'amd64' and 'arm64' naming in their package
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        LIB_DIR="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        LIB_DIR="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    echo "Installing SDRPlay API 3.15 for architecture: $ARCH (using $LIB_DIR)" && \
    # Install library and service daemon
    cp /tmp/${LIB_DIR}/libsdrplay_api.so.3.15 /usr/local/lib/ && \
    mkdir -p /opt/sdrplay_api && \
    cp /tmp/${LIB_DIR}/sdrplay_apiService /opt/sdrplay_api/ && \
    chmod +x /opt/sdrplay_api/sdrplay_apiService && \
    ln -sf /usr/local/lib/libsdrplay_api.so.3.15 /usr/local/lib/libsdrplay_api.so.3 && \
    ln -sf /usr/local/lib/libsdrplay_api.so.3 /usr/local/lib/libsdrplay_api.so && \
    # Install headers
    cp /tmp/inc/*.h /usr/local/include/ && \
    # Update library cache
    ldconfig && \
    # Cleanup
    rm -rf /tmp/SDRplay.run /tmp/amd64 /tmp/arm64 /tmp/armhf /tmp/inc /tmp/*.sh /tmp/*.txt && \
    echo "SDRPlay API 3.15 installed successfully"

# =============================================================================
# Build and install gr-sdrplay3 (GNU Radio SDRPlay blocks)
# =============================================================================
RUN git clone https://github.com/fventuri/gr-sdrplay3.git /tmp/gr-sdrplay3 && \
    cd /tmp/gr-sdrplay3 && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/gr-sdrplay3

# =============================================================================
# Cleanup
# =============================================================================
RUN apt-get clean -y && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Entrypoint setup
# =============================================================================
ADD ./entrypoint.sh /home/entrypoint.sh
RUN dos2unix /home/entrypoint.sh && \
    chmod +x /home/entrypoint.sh
ENTRYPOINT ["/home/entrypoint.sh"]

ENV DISPLAY=:0

# =============================================================================
# GNU Radio workspace - mount your flowgraphs here
# =============================================================================
RUN mkdir -p /workspace
VOLUME /workspace

# Set GRC_DIR to auto-load all .grc files in a directory (e.g., /workspace)
ENV GRC_DIR=""

# =============================================================================
# VNC authentication
# =============================================================================
ARG VNCPASSWD=mysecretpassword
RUN mkdir -p ~/.vnc && \
    x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd

EXPOSE 5900 6080

CMD ["/bin/bash"]
