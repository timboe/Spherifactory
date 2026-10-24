# Spherifactory

A 2D space-factory puzzle game. Build extractors, inserters, and factories around a living star, transmute resources into complex compounds, and ship them across ten handcrafted missions. Includes a sandbox mode and a campaign editor for building your own puzzles.

## Run

Requires Godot 3.6.2.

- Open `project.godot` in Godot 3.6.2 and press F5.
- Or run from PowerShell:

```powershell
godot --path .
```

## Controls

- Pan the camera: W/A/S/D, arrow keys, or middle-mouse drag.
- Zoom: mouse wheel, or Q (zoom out) / E (zoom in).
- Select a ring or place a building: left click.
- Cancel build or injection mode: right click.
- Pause or unpause: Space.
- Fast-forward, outlines, save/load, and menu: on-screen HUD buttons.

## Build

Install matching Godot 3.6.2 export templates, then use the **Windows Desktop** or **macOS** preset in `export_presets.cfg`.

Windows example:

```powershell
godot --path . --export "Windows Desktop" "build\windows\Spherifactory.exe"
```

macOS builds use ad-hoc signing and are not notarized. If Gatekeeper blocks the first launch, use right-click > Open, or remove the quarantine flag from the app. See `PRE_RELEASE_CHECKLIST.md` for the release process.

## Credits and licenses

Source code is MIT licensed; see `LICENSE.md`. Source repository: <https://github.com/timboe/Spherifactory>.

Third-party assets:

- Music: Adérito Silva - Rareness of Existence, Naval Proeminence, Phyllodia (Pixabay License)
- Sound effects: SilverIllusionist (CC-BY 4.0), Quistard (CC-BY 3.0), The-Sacha-Rush (CC0), waveplaySFX (CC0), Raclure (CC0), and SoundBible.com (CC-BY 3.0)
- Space backgrounds: fraang (OpenGameArt, CC-BY-SA 3.0)
- Advent Pro: Andreas Kalpakidis (OFL)
- Noto Sans: Google (OFL)
- Kenney particle pack: Kenney (CC0 1.0 Universal)
- Domain Warping: Oil: zaiyugi (Shadertoy)
- Icons: bqlqn, Pixel perfect, and Freepik via Flaticon; Noun Project contributors as listed in the in-game Credits screen
- Godot Engine: Godot Engine contributors (MIT)

Full attribution and license texts are available from the in-game Credits screen.
