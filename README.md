# ros2-picamera2-docker

Docker image for **picamera2** on **Raspberry Pi 5**, built on top of the official **`ros:jazzy-ros-base`** image. This can be useful for ros integration.

## Requirements

- Raspberry Pi 5 (64-bit OS, e.g. Ubuntu 24.04 or Raspberry Pi OS)
- Raspberry Pi Camera Module (tested with IMX708 / Camera Module 3)

## Connect your camera
#### Raspberry Pi OS
If you are running Raspberry Pi OS, all you need to do is to physically connect the camera to the SPI connector. Then you can check if your camera is installed properly in terminal:
```bash
rpicam-hello --list-cameras
```

#### Ubuntu 24.04
You will need extra steps to connect the camera in Ubuntu OS.
```bash
tee -a /boot/firmware/config.txt >/dev/null <<EOF
dtoverlay=imx708,cam0
dtoverlay=vc4-kms-v3d
EOF
```

## Install docker

#### Option 1 - Pull from docker hub
```bash
docker pull anthonyzyj/ros2-picamera2-docker:jazzy
```

#### Option 2 - Build from source

Build **on the Pi** (same CPU architecture as the robot):

```bash
git clone https://github.com/ICE9-Robotics/ros2-picamera2-docker.git
cd ros2-picamera2-docker
docker build -t ros2-picamera2:latest .
```

The build takes a while (compiles libcamera and kmsxx). It fails early if Python bindings are broken.

## Run the container

```bash
mkdir mnt

docker run -it --rm \
  --privileged \
  -v /run/udev:/run/udev:ro \
  -v "$(pwd)/mnt:/root/mnt" \
  ros2-picamera2:latest \
  bash
```

### dma_heap permissions

If you see `PermissionError: '/dev/dma_heap/linux,cma'`, the container user cannot open the DMA heap. For development you can temporarily run:

```bash
sudo chmod 666 /dev/dma_heap/linux,cma /dev/dma_heap/system
```

For production, add a udev rule:

```bash
sudo tee /etc/udev/rules.d/99-picamera2-dma-heap.rules >/dev/null <<EOF
SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Capture a test image

Inside the container:

```bash
python3 /root/capture_headless.py
```

This saves `demo.jpg` in the container working directory.

## License

MIT — see [LICENSE](LICENSE).
