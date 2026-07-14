# Image prompts — repo illustrations

Prompt pack for generating the README "my stack" banner (and future doc
illustrations) with [Gemini Nano Banana](https://gemini.google.com/) and OpenAI's
GPT image gen. Real screenshots stay canonical; AI art is for the hero banner and
the odd decorative header only — see the image strategy note in the README history.

## Method

Every prompt = **one reusable base scene** + **one style modifier** + **the global
rules**. Keep the base and rules fixed; swap only the style line to explore looks.

> [!IMPORTANT]
> Both Nano Banana and GPT image gen still garble small text and real logos. Do
> **not** rely on legible tool names or accurate brand logos in the pixels — keep
> names as crisp Markdown (the `What I use` table) or a post-gen SVG overlay.

### Palette (Catppuccin)

The setup runs Catppuccin, auto-switched Latte (light) / Mocha (dark).

- **Mocha (dark):** base `#1e1e2e`, text `#cdd6f4`, mauve `#cba6f7`, lavender
  `#b4befe`, teal `#94e2d5`, pink `#f5c2e7`, peach `#fab387`
- **Latte (light):** base `#eff1f5`, text `#4c4f69`, mauve `#8839ef`, blue
  `#1e66f5`, teal `#179299`
- Signature accent: **mauve + lavender**.

### Global rules (paste at the end of every prompt)

```text
Wide banner composition, ~2.6:1 aspect ratio, subject slightly right of center
with calm negative space on the left. Catppuccin palette, soft pastel, gentle
bloom and rim light, cozy and clean. IMPORTANT: no text, no letters, no words, no
UI labels, no real brand logos, no watermark, no signature. Cohesive single scene.
```

### Base scene (the constant)

```text
An isometric 3/4-view illustration of a cozy developer workspace: a slim laptop on
a warm wooden desk, its screen showing abstract vertical columns of app windows
sliding sideways (evoking a scrollable-tiling desktop) with one glowing terminal
window; a small potted cactus, a ceramic coffee mug with steam, a low-profile
mechanical keyboard, and over-ear headphones nearby; a softly blurred bokeh room
behind, warm ambient light.
```

## Style variants (swap this one line)

### 1 — Modern (flat vector + glass)

```text
Style: modern flat vector illustration with subtle glassmorphism, smooth gradient
fills, crisp geometric shapes, gentle long shadows, dribbble/tech-brand aesthetic,
high polish.
```

### 2 — Simple / minimal

```text
Style: minimalist line illustration, very few elements, thin uniform strokes, lots
of flat negative space, two or three pastel tones only, calm and uncluttered.
```

### 3 — Sketch (hand-drawn)

```text
Style: loose hand-drawn pencil-and-pen sketch on off-white paper, visible
construction lines, light cross-hatching, notebook/doodle feel, imperfect and
warm, soft pastel color washes.
```

### 4 — Ink (bold linework)

```text
Style: bold ink illustration, confident black brush linework, high-contrast, subtle
halftone/risograph texture, limited palette of one or two Catppuccin accents over
ink, screen-print poster feel.
```

### 5 — Primary accent (mono + one color)

```text
Style: near-monochrome dark scene (Catppuccin Mocha base and surfaces) with a
single dominant mauve/lavender accent (#cba6f7) glowing on the terminal and rim
lights; everything else desaturated, dramatic and focused.
```

### 6 — Background (low-contrast, title-safe)

```text
Style: soft ambient background art, low contrast, gentle blur and grain, muted
pastel gradient, minimal detail, plenty of even empty space so bold title text can
be overlaid on top; wallpaper-like, unobtrusive.
```

### Bonus — Isometric 3D render

```text
Style: clean isometric low-poly 3D render, soft studio lighting, matte clay
materials with subtle mauve emissive glow, blender/octane look, rounded edges.
```

### Bonus — Pixel art

```text
Style: cozy 32-bit pixel-art scene, crisp dithering, limited Catppuccin palette,
warm lamp glow, retro-desktop vibe, no anti-aliasing.
```

## Tool-specific tips

- **Gemini (Nano Banana / 2.5 Flash Image):** strong at scene coherence and
  iterating. Attach `images/screenshot/terminal-desktop-light.png` as a reference
  and say "match this color mood." No aspect-ratio field in-app — state "wide 2.6:1
  banner" and crop after. Fix drift conversationally ("more negative space left,
  dim the background").
- **GPT image gen (gpt-image-1):** takes a `size` param — generate at
  **1536×1024 (landscape)** then crop. It tends to invent text, so keep the
  "no text/letters/logos" rule verbatim and never name tools inside the scene.

## After generating

- **Crop** to the banner box (≈1280×490 for a README hero), then convert:
  `cwebp -q 82 in.png -o images/banner/stack-dark.webp` (or AVIF via `avifenc`).
  Aim under ~150 KB — it's committed to a public repo.
- Want **light + dark**? Generate a Latte and a Mocha version; the `<picture>`
  scaffold in the README swaps them by `prefers-color-scheme`, mirroring the
  `auto-sync-theme` setup.
- Tool **names** live in the `What I use` table under the banner, so the image
  never needs legible text to do its job.
