import base64
import os
import sys

import requests

url = "https://api.minimaxi.com/v1/image_generation"
api_key = os.environ.get("MINIMAX_API_KEY", "").strip()
if not api_key:
    raise SystemExit("MINIMAX_API_KEY environment variable is required")

headers = {"Authorization": f"Bearer {api_key}"}

prompt = sys.argv[1]
width = int(sys.argv[2])
height = int(sys.argv[3])
output_filename = sys.argv[4]

payload = {
    "model": "image-01",
    "prompt": prompt,
    "width": width,
    "height": height,
    "n": 1,
    "response_format": "base64",
}

response = requests.post(url, headers=headers, json=payload)
response.raise_for_status()

image_base64 = response.json()["data"]["image_base64"][0]

with open(output_filename, "wb") as f:
    f.write(base64.b64decode(image_base64))

print(f"Saved {output_filename}")
