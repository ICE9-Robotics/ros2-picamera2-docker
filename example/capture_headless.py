#!/usr/bin/env python3

from picamera2 import Picamera2

picam2 = Picamera2()
config = picam2.create_still_configuration()
picam2.configure(config)

picam2.start()

np_array = picam2.capture_array()
print(np_array.shape)
picam2.capture_file("/root/mnt/demo.jpg")
picam2.stop()
print("Saved /root/mnt/demo.jpg")