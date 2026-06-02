# Build from-source libcamera + kmsxx + picamera2 (Pi 5, Raspberry Pi OS 64-bit).
#
# Build on the Pi:
#   docker build -t picamera2:latest .
#
# Examples:
#   docker build --build-arg ROS_DISTRO=humble --build-arg PICAMERA2_COMMIT=v0.3.0 -t picamera2:humble .
#   docker build --build-arg LIBCAMERA_COMMIT=v0.5.0 --build-arg PICAMERA2_COMMIT=v0.3.27 -t picamera2:latest .

ARG ROS_DISTRO=jazzy
ARG LIBCAMERA_COMMIT=main
ARG PICAMERA2_COMMIT=main

FROM ros:${ROS_DISTRO}-ros-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        meson \
        ninja-build \
        pkg-config \
        python3-dev \
        pybind11-dev \
        python3-pip \
        python3-yaml \
        python3-ply \
        python3-jinja2 \
        python3-opencv \
        libyaml-dev \
        libevent-dev \
        libdrm-dev \
        libcap-dev \
        libegl-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        openssl \
        libssl-dev \
        libboost-dev \
        libgnutls28-dev \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/git_clone_ext.sh /usr/local/bin/git_clone_ext.sh
RUN chmod +x /usr/local/bin/git_clone_ext.sh

RUN /usr/local/bin/git_clone_ext.sh \
        https://github.com/raspberrypi/libcamera.git \
        /tmp/libcamera \
        "$LIBCAMERA_COMMIT" \
    && cd /tmp/libcamera \
    && meson setup build --buildtype=release \
        -Dpipelines=rpi/vc4,rpi/pisp \
        -Dipas=rpi/vc4,rpi/pisp \
        -Dv4l2=true \
        -Dgstreamer=enabled \
        -Dtest=false \
        -Dlc-compliance=disabled \
        -Dcam=disabled \
        -Dqcam=disabled \
        -Ddocumentation=disabled \
        -Dpycamera=enabled \
    && ninja -C build install \
    && ldconfig \
    && test -n "$(find /usr/local -name '_libcamera*.so' -print -quit)" \
    && rm -rf /tmp/libcamera

RUN git clone --depth 1 https://github.com/tomba/kmsxx.git /tmp/kmsxx \
    && meson setup /tmp/kmsxx/build /tmp/kmsxx \
        -Dpykms=enabled \
    && ninja -C /tmp/kmsxx/build install \
    && ldconfig \
    && test -n "$(find /usr/local -path '*/pykms/pykms*.so' -print -quit)" \
    && rm -rf /tmp/kmsxx

ARG PICAMERA2_COMMIT=main
RUN /usr/local/bin/git_clone_ext.sh \
        https://github.com/raspberrypi/picamera2.git \
        /tmp/picamera2 \
        "$PICAMERA2_COMMIT" \
    && cd /tmp/picamera2 \
    && (pip3 install . --break-system-packages --no-deps \
        || pip3 install . --no-deps) \
    && (pip3 install PiDNG piexif simplejpeg v4l2-python3 av numpy pillow python-prctl videodev2 --break-system-packages \
        || pip3 install PiDNG piexif simplejpeg v4l2-python3 av numpy pillow python-prctl videodev2) \
    && rm -rf /tmp/picamera2

RUN python3 <<'PY'
from pathlib import Path

site_dirs: list[str] = []

def add(path: Path) -> None:
    s = str(path)
    if path.is_dir() and s not in site_dirs:
        site_dirs.append(s)

for pattern in ("_libcamera*.so", "pykms*.so", "pykms.cpython*.so"):
    for so in Path("/usr/local").rglob(pattern):
        add(so.parent.parent)

Path("/etc/lyra-pythonpath").write_text(":".join(site_dirs))
print("PYTHONPATH:", site_dirs)
PY

RUN export PYTHONPATH="$(cat /etc/lyra-pythonpath)" \
    && cd /tmp \
    && python3 -c "from libcamera import ControlType; print('libcamera OK:', ControlType)" \
    && python3 -c "import pykms; print('pykms OK:', pykms.__file__)" \
    && python3 -c "from picamera2 import Picamera2; print('picamera2 OK')"

RUN echo 'export PYTHONPATH="$(cat /etc/lyra-pythonpath 2>/dev/null)"' >> /root/.bashrc

WORKDIR /root

COPY example/capture_headless.py /root/capture_headless.py

CMD ["bash"]
