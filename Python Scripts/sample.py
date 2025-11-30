import os
import requests

# Folder to save images
SAVE_FOLDER = "sample"
os.makedirs(SAVE_FOLDER, exist_ok=True)

# Number of images to fetch
NUM_IMAGES = 25

for i in range(1, NUM_IMAGES + 1):
    url = f"https://picsum.photos/600/600"
    filename = os.path.join(SAVE_FOLDER, f"img_{i}.jpg")

    print(f"Downloading Image {i} from {url}...")

    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()  # check for errors

        with open(filename, "wb") as f:
            f.write(response.content)

        print(f"Saved to {filename}")

    except Exception as e:
        print(f"Failed to download image {i}: {e}")

print("\n✅ Done! Images saved in the 'sample' folder.")
