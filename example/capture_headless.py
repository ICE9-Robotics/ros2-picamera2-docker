from pathlib import Path

from picamera2 import Picamera2


picam2 = Picamera2()
config = picam2.create_still_configuration()
picam2.configure(config)

picam2.start()

np_array = picam2.capture_array()
print(f"Image shape: {np_array.shape}")

image_dir = Path(__file__).parent / "mnt"

if not image_dir.exists():
    image_dir.mkdir(parents=True, exist_ok=True)
    
picam2.capture_file(image_dir / "demo.jpg")
picam2.stop()
print(f"Saved {image_dir / 'demo.jpg'}")