# Media-Assets

Graphics, branding, and promotional assets for ZamRock Radio.

```
Media-Assets/
├── Brand/          — Core identity (logos, backgrounds, favicon)
├── Social/         — Social media assets (banners, PFP, emoji, posts)
├── Promo/          — Promotional GIFs and pics
├── Press/          — Press kit and press release assets
├── Bots/           — Bot and server graphics (stoat, webhooks)
├── Repos/          — Repo banners (CLI, etc.)
└── Tools/          — Scripts for working with assets
```

## Watermark Tool

`Tools/watermark.py` adds ZamRock branding to images:

```bash
# Watermark a file (saves copy next to original)
python3 Tools/watermark.py path/to/image.jpg

# Save to Press/releases/ with timestamp
python3 Tools/watermark.py path/to/image.jpg --press
```

**Branch rule:** Always use the `watermark-maker` branch when watermarking repo pics. This keeps watermarked outputs separate from the main branch.

```
git checkout watermark-maker
# run watermark tool…
git add Press/releases/   # if committing outputs
```

## Usage

- **Press inquiries:** See `Press/` for logos, bio, and watermarked images
- **Social media:** Banners, profile pics, and emoji in `Social/`
- **Stream promotion:** Animated GIFs and images in `Promo/`

## Related

- [[ZamRock Radio]] — main station hub
- [[Media/Media-Assets]] — Obsidian vault overview
- [[Station/Brand]] — brand identity and colors
- [[Post Factory]] — publishing workflow
