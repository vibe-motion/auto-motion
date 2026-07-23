---
name: image-gen
description: Generate a single image from a text prompt using the MiniMax image generation API. Use when the user asks to create, generate, or render an image from a prompt and explicit width/height.
---

# image-gen

Generate one image from a text prompt via MiniMax `image-01` model. The output file is written to the filename you pass as the 4th argument (relative to the caller's cwd).

Set the MiniMax API key in the environment before running the script. Never write the key into this repository:

```bash
export MINIMAX_API_KEY="<your-api-key>"
```

The script path is resolved relative to this SKILL.md (not the caller's cwd), so it works from any directory. It accepts exactly four positional arguments: prompt, width, height, output_filename.

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/scripts/image-gen.py" "<prompt>" <width> <height> <output_filename>
```

| Argument | Type | Constraints |
|---|---|---|
| prompt | string | ≤ 1500 chars; describe subject + style + mood |
| width | int | 512–2048, must be a multiple of 8 |
| height | int | 512–2048, must be a multiple of 8 |
| output_filename | string | Filename to write the image to, relative to cwd (e.g. `img1.png`). The file extension is preserved as-is. |


## Output

- File: `<output_filename>` (relative to cwd — the directory the command is invoked from)
- Format: raw image bytes base64-decoded from the API response; extension is whatever you pass (e.g. `.png`, `.jpeg`)
- Always overwrites an existing file at the same path

After running, confirm the file exists with `ls -lh <output_filename>` and report the absolute path to the user.

## Prompt writing tips

Be explicit about style to avoid photorealistic defaults. Example style keywords:

- **Flat / UI / vector**: `UI style`, `flat illustration`, `vector art`, `minimalist`, `clean cut-and-paste aesthetic`, `no photography no realistic textures`
- **Collage / cut-and-paste**: `paper cut collage`, `layered flat cut-out shapes`, `torn paper edges`, `mixed media`
- **Vintage / retro**: `vintage paper collage`, `sun-faded tones`, `retro travel poster`
- **Photorealistic**: `photorealistic`, `documentary photography`, `film grain`

Combine subject + style + palette. Example structure:
`"<style keywords>: <subject>, <key visual elements>, <color palette>, <negative constraints>"`

## Examples

### 1. Santorini paper-cut collage (UI style, non-photorealistic)

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/scripts/image-gen.py" "UI style paper cut collage of Santorini, Greece: whitewashed houses with blue domes, ancient Greek columns, olive branches, terracotta rooftops, layered flat cut-out shapes with torn paper edges, clean vector illustration, minimalist cut-and-paste aesthetic, pastel color palette, no photography no realistic textures" 512 512 santorini.png
```

### 2. Square UI icon (1:1)

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/scripts/image-gen.py" "flat vector icon of a paper airplane, minimal geometric shapes, soft blue and white palette, clean UI illustration, no shadows no gradients" 512 512 airplane.png
```

### 3. Landscape banner (16:9)

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/scripts/image-gen.py" "minimalist flat illustration of mountains at sunset, layered geometric shapes, warm orange and purple palette, clean vector style, no texture no realism" 1280 720 mountains.png
```

### 4. Portrait poster (2:3)

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/scripts/image-gen.py" "vintage paper collage portrait of a woman in 1920s fashion, torn paper layers, muted sepia and teal tones, art deco cut-out shapes, mixed media aesthetic" 832 1248 portrait.png
