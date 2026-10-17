# Room brand assets

The supplied official artwork is the source of truth. `black/` uses the original
near-black `#111111`; `white/` uses `#FFFFFF`. All backgrounds are transparent.

- `lockup.svg`: complete supplied 460 × 141 composition, including the intentional
  vertical offset and original spacing. Do not recenter the symbol or lettering.
- `logo.svg`: standalone symbol, 170 × 141, with its original path coordinates.
- `wordmark.svg`: outlined lettering only, cropped with a viewBox rather than
  transforming or redrawing paths. Its original coordinates and proportions stay
  intact; use the lockup whenever the symbol and lettering appear together.
- `room.icon`: the editable Icon Composer app icon. Keep its internal `icon.json`
  and `Assets/` together; use the standalone logo above for the menu-bar template.
- `Room.icns`: the built Finder **volume** icon. `room` installs it on a mounted
  share as `.VolumeIcon.icns` (Apple's fixed name) and sets the custom-icon flag.
  Rebuild it from `room.icon` when the artwork changes.

Naming: the only Apple-defined file here is the applied `.VolumeIcon.icns` at the
volume root. Everything else is our own source naming; there is no Apple
"sidebar icon" asset.

No font files, strokes, embedded images, scripts, or external resources are needed.
Cleanup is limited to consistent SVG formatting; no geometric corrections were
made. Preserve the `evenodd` fill rule on both letters “o”. For accessible HTML,
provide suitable `alt` text on the embedding image (or empty text when decorative).
