# Style blocks for ChatGPT image prompts

Paste the blocks a prompt file asks for at the start of each chat (one chat per part). Canvas: square 1024, wide 1536×1024, tall 1024×1536. Save with the exact file name into `assets/…` and ask Claude to import the art.

```text
UI STYLE BLOCK:
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved plate coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast,
warm lamplight against cold fog. Late-19th-century craftsmanship fused with
advanced machinery (brass, rivets, glass, pipes). Ominous, quiet, human-scale details.
No text, no letters, no numbers, no watermarks, no modern objects, no neon, no anime style.
```

```text
TRANSPARENT BLOCK:
Output a PNG with a fully transparent background (real alpha channel): no background colour,
no floor, no table, no checkerboard pattern, no frame around the image, no cast shadow.
A single game interface element, front view, centred, nothing else in the image.
Clean edges; the element itself is opaque (glass may be slightly see-through).
Engraved, hand-painted look matching the style block. Even soft light from the top-left.
No text, no letters, no numbers.
```

```text
SCENE STYLE BLOCK:
Realistic painterly concept art of a Victorian slum at night after rain, like a matte painting for a dark
detective game. Desaturated cold palette: wet slate grey, soot black, blue-grey fog, dark brick brown; small warm
amber points of gas lamps and lit windows; no bright colours. Wet glistening stone and cobbles, puddles
reflecting lamplight, chimney smoke, low fog. Crooked, cramped, patched with planks; grime, moss, washing lines.
No ink outlines, no cartoon, no anime. No text, no letters, no numbers, no signs with writing, no watermark.
```

```text
TEXTURE BLOCK:
A seamless tileable texture that fills the whole square canvas edge to edge: the left edge continues into the
right edge and the top edge into the bottom edge without a seam. Evenly the same everywhere: no centre, no
vignette, no frame, no objects, no light spot, no shadows from the side. Flat front view.
```


```text
LIFE STYLE BLOCK:
Realistic painterly figures for a dark Victorian slum at night after rain, the same look as the attached map piece:
desaturated cold palette (wet slate grey, soot black, blue-grey, dark brick brown), small warm amber highlights from
lamps. Each figure has a crisp, readable silhouette and a thin cool rim light so it reads on dark wet cobbles when tiny.
Camera: high above, looking down at about 60 degrees, like the attached map — we see hats, shoulders and the top of
the figure, a little of the body. Clothing of the 1880s with gaslight-and-steel details (brass, rivets, leather).
No text, no letters, no numbers, no logos.
```

```text
SPRITE BLOCK:
Transparent background (real alpha channel). No ground, no floor, no cast shadow, no frame.
Each element is complete and not cut off, with a clear empty margin around it.
```


```text
SHEET: one image with eight separate figures on a 4 x 2 grid, exactly in the numbered slots of the attached layout
guide (slot 1 top-left, reading order). Every figure stands in the middle of its slot, all at the same scale (an
adult fills about two thirds of the slot height). Figures never touch or overlap. Do not draw the slot numbers,
lines or the guide.
```
