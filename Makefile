# =============================================================================
# GNU Radio + SDRPlay Docker Image Makefile
# =============================================================================
# Supports building for x86_64 (amd64) and arm64 architectures
# =============================================================================

IMAGE_NAME ?= gnuradio-sdrplay
IMAGE_TAG ?= latest
CONTAINER_NAME ?= gnuradio-sdrplay
VNC_PORT ?= 6080
VNC_PASSWORD ?= mysecretpassword
WORKSPACE ?= $(PWD)/workspace

# Detect current architecture
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    CURRENT_ARCH := amd64
else ifeq ($(UNAME_M),aarch64)
    CURRENT_ARCH := arm64
else ifeq ($(UNAME_M),arm64)
    CURRENT_ARCH := arm64
else
    CURRENT_ARCH := $(UNAME_M)
endif

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "GNU Radio + SDRPlay Docker Image"
	@echo "================================="
	@echo ""
	@echo "Build targets:"
	@echo "  make build           - Build for current architecture ($(CURRENT_ARCH))"
	@echo "  make build-amd64     - Build for x86_64/amd64"
	@echo "  make build-arm64     - Build for arm64/aarch64 (Raspberry Pi)"
	@echo "  make build-multiarch - Build for both architectures (requires buildx)"
	@echo ""
	@echo "Run targets:"
	@echo "  make run             - Run container with SDR device mounted"
	@echo "  make run-no-sdr      - Run container without SDR device"
	@echo "  make shell           - Open a shell in running container"
	@echo "  make stop            - Stop the container"
	@echo "  make logs            - View container logs"
	@echo ""
	@echo "SDRPlay service (optional - service auto-starts in container):"
	@echo "  make sdrplay-start   - Start SDRPlay API service on host (if needed)"
	@echo "  make sdrplay-stop    - Stop SDRPlay API service on host"
	@echo "  make sdrplay-status  - Check SDRPlay API service status"
	@echo ""
	@echo "Utility targets:"
	@echo "  make clean           - Remove container"
	@echo "  make clean-all       - Remove container and image"
	@echo "  make setup-udev      - Install SDRPlay udev rules on host"
	@echo ""
	@echo "Variables (can be overridden):"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  VNC_PORT=$(VNC_PORT)"
	@echo "  VNC_PASSWORD=$(VNC_PASSWORD)"
	@echo "  WORKSPACE=$(WORKSPACE)"
	@echo ""
	@echo "Example:"
	@echo "  make run GRC_DIR=/workspace  # Opens all .grc files in directory"

# =============================================================================
# Build targets
# =============================================================================

.PHONY: build
build:
	@echo "Building for current architecture: $(CURRENT_ARCH)"
	docker build \
		--build-arg VNCPASSWD=$(VNC_PASSWORD) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		.

.PHONY: build-amd64
build-amd64:
	@echo "Building for amd64 (x86_64)..."
	docker buildx build \
		--platform linux/amd64 \
		--build-arg VNCPASSWD=$(VNC_PASSWORD) \
		-t $(IMAGE_NAME):$(IMAGE_TAG)-amd64 \
		--load \
		.

.PHONY: build-arm64
build-arm64:
	@echo "Building for arm64 (aarch64/Raspberry Pi)..."
	docker buildx build \
		--platform linux/arm64 \
		--build-arg VNCPASSWD=$(VNC_PASSWORD) \
		-t $(IMAGE_NAME):$(IMAGE_TAG)-arm64 \
		--load \
		.

.PHONY: build-multiarch
build-multiarch:
	@echo "Building for multiple architectures..."
	@echo "Note: This requires docker buildx and may push to a registry"
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg VNCPASSWD=$(VNC_PASSWORD) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		.

# =============================================================================
# Run targets
# =============================================================================

# Create workspace directory if it doesn't exist
$(WORKSPACE):
	mkdir -p $(WORKSPACE)

.PHONY: run
run: $(WORKSPACE)
	@echo "Starting container with SDR device access..."
	@echo "Access GNU Radio Companion at: http://localhost:$(VNC_PORT)/vnc.html"
	@echo "VNC Password: $(VNC_PASSWORD)"
	@echo ""
	@echo "NOTE: SDRPlay API service starts automatically inside the container."
	@echo "      The container runs with --privileged for USB device access."
	@echo ""
	docker run -d --rm \
		--name $(CONTAINER_NAME) \
		--privileged \
		-p $(VNC_PORT):6080 \
		-v /dev/bus/usb:/dev/bus/usb \
		-v /dev/shm:/dev/shm \
		$(if $(GRC_DIR),-e GRC_DIR=$(GRC_DIR),) \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		sleep infinity
	@echo ""
	@echo "Container started! Access at http://localhost:$(VNC_PORT)/vnc.html"

.PHONY: run-no-sdr
run-no-sdr: $(WORKSPACE)
	@echo "Starting container WITHOUT SDR device..."
	@echo "Access GNU Radio Companion at: http://localhost:$(VNC_PORT)/vnc.html"
	docker run -d --rm \
		--name $(CONTAINER_NAME) \
		-p $(VNC_PORT):6080 \
		$(if $(GRC_DIR),-e GRC_DIR=$(GRC_DIR),) \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		sleep infinity
	@echo ""
	@echo "Container started! Access at http://localhost:$(VNC_PORT)/vnc.html"

.PHONY: stop
stop:
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

.PHONY: logs
logs:
	docker logs -f $(CONTAINER_NAME)

# =============================================================================
# SDRPlay API Service (must run on HOST)
# =============================================================================
# The SDRPlay API service daemon must run on the host system, not in the container.
# The container accesses the SDR through USB passthrough and shared memory.

.PHONY: sdrplay-start
sdrplay-start:
	@echo "Starting SDRPlay API service on host..."
	@if [ -f /opt/sdrplay_api/sdrplay_apiService ]; then \
		sudo /opt/sdrplay_api/sdrplay_apiService &; \
		echo "SDRPlay API service started."; \
	elif command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q sdrplay; then \
		sudo systemctl start sdrplay; \
		echo "SDRPlay API service started via systemd."; \
	else \
		echo "ERROR: SDRPlay API not found on host."; \
		echo "Please install the SDRPlay API on your host system:"; \
		echo "  wget https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.15.2.run"; \
		echo "  chmod +x SDRplay_RSP_API-Linux-3.15.2.run"; \
		echo "  sudo ./SDRplay_RSP_API-Linux-3.15.2.run"; \
		exit 1; \
	fi

.PHONY: sdrplay-stop
sdrplay-stop:
	@echo "Stopping SDRPlay API service on host..."
	@if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q sdrplay; then \
		sudo systemctl stop sdrplay; \
	else \
		sudo pkill -f sdrplay_apiService || true; \
	fi
	@echo "SDRPlay API service stopped."

.PHONY: sdrplay-status
sdrplay-status:
	@echo "SDRPlay API service status:"
	@if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q sdrplay; then \
		systemctl status sdrplay --no-pager || true; \
	else \
		pgrep -a sdrplay_apiService || echo "SDRPlay API service is not running."; \
	fi

# =============================================================================
# Utility targets
# =============================================================================

.PHONY: setup-udev
setup-udev:
	@echo "Installing SDRPlay udev rules on host..."
	@echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"' | sudo tee /etc/udev/rules.d/66-sdrplay.rules
	sudo udevadm control --reload-rules
	sudo udevadm trigger
	@echo "Udev rules installed. You may need to reconnect your SDRPlay device."

.PHONY: clean
clean:
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

.PHONY: clean-all
clean-all: clean
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG)-amd64 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG)-arm64 2>/dev/null || true

# =============================================================================
# Development helpers
# =============================================================================

.PHONY: start
start: build run-no-sdr

.PHONY: stop
stop: clean

.PHONY: shell
shell: build
    docker run --rm -it \
        --name $(CONTAINER_NAME) \
        -p $(VNC_PORT):6080 \
        $(if $(GRC_DIR),-e GRC_DIR=$(GRC_DIR),) \
        $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: rebuild
rebuild: clean-all build

.PHONY: test
test: build run-no-sdr
	@echo "Waiting for container to start..."
	@sleep 5
	@echo "Testing VNC connectivity..."
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:$(VNC_PORT)/vnc.html | grep -q 200 && \
		echo "SUCCESS: VNC interface is accessible" || \
		echo "FAILURE: VNC interface not responding"
	@echo ""
	@echo "Checking GNU Radio installation..."
	@docker exec $(CONTAINER_NAME) gnuradio-companion --version || true
	@echo ""
	@echo "Checking gr-sdrplay3 installation..."
	@docker exec $(CONTAINER_NAME) python3 -c "import sdrplay3; print('gr-sdrplay3 loaded successfully')" 2>/dev/null || \
		echo "Note: gr-sdrplay3 module check - run inside GNU Radio Companion"
