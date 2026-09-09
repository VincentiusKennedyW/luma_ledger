# Luma Ledger icon

The launcher mark is an ivory ledger-shaped wallet with one gold coin on evergreen. It replaces the ascending bars that looked like cellular signal strength. The silhouette is designed to remain recognizable at launcher sizes without text or currency symbols.

- Generated master: `assets/branding/luma-icon-master.png`
- Exact built-in image-generation prompt: `assets/branding/luma-icon.prompt.txt`
- App asset: `assets/luma-icon.png`
- Native exports: Android mipmap densities, iOS AppIcon asset catalog, and macOS AppIcon asset catalog.
- Export command on macOS: `swift tool/render_icon.swift`

The master was generated using the built-in image-generation tool on 2026-09-09. Native images are opaque RGB PNGs resized from that master, with unrounded square edges so the operating system controls the launcher mask. Do not recreate the retired signal-bar SVG or substitute chart bars for the brand mark. The in-app Insights chart icon remains a functional navigation symbol, not the brand icon.

When re-exporting, preserve provenance using the exact prompt file. The icon does not settle the pending application-wide redesign direction.
