# Profile Desk motion assets

Original geometric artwork authored for Profile Desk. No downloaded animations,
third-party images, fonts, remote URLs, expressions, or embedded scripts.

- `accounts.json`: three distinct profile tiles arrange on a desk.
- `opening.json`: a compact workspace unfolds once.
- `privacy.json`: layered shields settle behind a simple check.

Each transparent 360 × 320 composition runs at 30 fps for less than two seconds.
`DeskScene` plays once and keeps the final frame. Reduced motion and accessible
navigation display that final frame immediately; inactive and hidden scenes stop
ticking. These illustrations do not claim an observed service connection,
completed account linking, or absolute screen-capture protection.

The Python standard-library source in `author_scenes.py` deterministically rebuilds
all three JSON files. Only the JSON assets should be bundled in the application.
Artwork and generator are original project source and follow the repository's
applicable licensing terms.
