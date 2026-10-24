# Spherifactory Pre-Release Checklist

Working checklist for the first public release.

| Field | Value |
| --- | --- |
| Release version | `1.0` |
| Release date | TBD |
| Last updated | 2026-10-24 |
| Engine | Godot `3.6.2` stable |
| Export templates | Installed |
| Platforms | Windows (itch.io), macOS (itch.io, ad-hoc signed) |
| Android | Post-launch readiness track (Appendix A); not required for this release |
| Release owner | TBD |
| Source commit / tag | TBD |
| Windows build | TBD |
| macOS build | TBD |

How to use this document:

- **P0** items block the release.
- The remaining sections are **P1** by default and must be completed before
  uploading the final build. Items marked optional or conditional can be
  deferred only with a recorded decision.
- Tick each box, add the date, and note the evidence (build hash, device, OS,
  screenshot path, or test result).
- Do not publish while any P0 item is unchecked.
- This checklist reflects the initial read-only audit. Completed configuration
  and content-cleanup items are marked; platform QA and the actual exports are
  deliberately deferred until the configuration pass is finished.
- Git and repository hygiene are being handled by the project owner.

## P0 - release blockers and audit follow-ups

### Repository and toolchain

> **Deferred:** Git operations and repository hygiene are handled by the project
> owner. Do not action this subsection in the current pass.

- [ ] Install Git for Windows (or make Git available on `PATH`).
- [ ] Back up the working copy and `.git` before any repair work.
- [ ] Move or clone the project outside Dropbox for release work. If that is not possible, pause Dropbox syncing while using Git.
- [ ] Remove Dropbox conflict copies from `.git` only after the backup and a successful `git fsck --full`. Current conflict copies include `index`, `FETCH_HEAD`, remote logs, and `multi-pack-index`. Remove the stale `FETCH_HEAD.lock` only after confirming no Git process is running.
- [ ] Run `git status`, `git diff`, and `git log` and review all current work. The audit found 61 tracked files whose current content differs from the staged index and 122 untracked files.
- [ ] Commit intended work and confirm a clean working tree before tagging.
- [x] Update `.gitignore` so `export_presets.cfg` is tracked and `*.import` files are tracked; only the `.import/` cache is ignored.
- [x] Remove stale `.gitignore` entries that refer to deleted asset directories.
- [x] Add build/export output directories to `.gitignore`.
- [x] Install Godot 3.6.2 export templates (confirmed installed).
- [x] Confirm the project opens and runs with Godot 3.6.2, not Godot 4 (smoke test passed with no parser errors).

### Project configuration

- [x] Change `display/window/stretch/mode` from `"canvas_items"` to `"2d"` in `project.godot`. `canvas_items` is a Godot 4 value; Godot 3.6 expects `"2d"`, `"viewport"`, or `"disabled"`.
- [x] Set Android orientation explicitly to sensor landscape (`window/handheld/orientation=4`).
- [x] Set `application/config/version` to `1.0`, add the short description, and set the 2026 copyright. The default `user://` path is intentionally retained for 1.0.
- [x] Make Space pause-only. `ui_select` no longer contains the Space key; `ui_pause` keeps it.

### Debug and shipping content

- [x] Disable the trailer debug overlay. `TrailerController.show_debug` is now `false`.
- [x] Move the trailer easter egg from `T` to `F10` and remove the `trail_start` input action. The debug overlay is not shown during normal play.
- [x] Remove `test_save.json` and the unused `test_save` constant in `titlescripts/NewGame.gd`.
- [x] Remove `TestScene1.tscn`, `TestScene2.tscn`, `ss.png`, and root `icon.png`. Retain `levels.txt` and `.pdn` source art intentionally.
- [x] Remove the stale `images/ship.png.import` file; its source image is missing.
- [ ] Runtime asset cleanup is deferred by the project owner: `images/spacefield_a-000.png`, `resources/MinimalWindowPanelStyleWindow.tres`, and unused WAVs remain in the project.
- [x] Remove legacy unreferenced fonts/translations: `fonts/font.ttf`, `fonts/font_big.ttf`, `fonts/texte.csv`, `fonts/texte.en.translation`, and `fonts/texte.fr.translation`.

### Export configuration

- [x] Fix the Windows and macOS presets so `resources/campaign_data.json` is included. Both use `export_filter="all_resources"` plus `include_filter="resources/campaign_data.json"`, which also covers dynamically loaded gem textures and translations.
- [x] Fill in Windows version metadata: file version and product version `1.0.0.0`, file description, company, and 2026 copyright.
- [ ] Verify the exported Windows build on a clean machine with no existing user data. Confirm the built-in campaign appears and all 10 levels can be started.
- [x] Create a macOS export preset.
- [x] Choose the macOS bundle identifier (`com.timboe.spherifactory`), app category, version (`1.0`), copyright (`2026 Tim Martin`), and the built-in universal template.
- [x] Set the macOS icon to `images/ico.png`; Godot 3.6 generates the `.icns` during export.
- [x] Configure built-in ad-hoc signing (`codesign/codesign=1`) with notarization disabled. The actual export and Gatekeeper documentation remain for the owner.
- [ ] Test the exported macOS build on both Intel and Apple Silicon if both are available.
- [ ] Verify that translations, autoload scenes (`Music.tscn`, `Sfx.tscn`), audio, and all runtime scenes are present in the exported builds.

### Visible content and credits

- [x] Fix the credits mojibake (Adérito Silva and Rafael Farias Leão) in `Title.tscn`, including the footer.
- [x] Update the credits and `LICENSE.md` year from 2021 to 2026.
- [x] Add missing credits for sound effects and the remaining Flaticon/Noun Project contributors.
- [x] Confirm the source-code link in the credits points to the public repository (`github.com/timboe/Spherifactory`).
- [x] Add attribution for the space backgrounds (CC-BY-SA 3.0), music (Pixabay), sound effects (Freesound/SoundBible), and fonts (OFL).
- [x] Confirm the Freesound/SoundBible sound-effect licenses permit commercial distribution (CC0/CC-BY; attribution and license URIs added).
- [x] Confirm the in-game credits include the full OFL, CC-BY-SA 3.0, CC0, and Godot MIT license texts, plus links/attribution for the remaining assets.

## 1. Release freeze and repository hygiene

> **Deferred:** the project owner is handling Git operations and repository
> repair. Leave this section unchecked for now.

- [ ] Freeze feature work on `main` or create a `release/1.0` branch.
- [ ] Record the source commit that will be tagged.
- [ ] Confirm there are no secrets, keystores, passwords, personal paths, or local-only configuration in the commit.
- [ ] Confirm no `.import/` cache, `build/`, user saves, screenshots, `.pck`, `.apk`, or export folders are staged.
- [ ] Confirm `.git` passes `git fsck --full`.
- [ ] Confirm `git status` is clean after the final commit.
- [ ] Tag the final source commit (for example `v1.0.0`) after the final build passes QA.
- [ ] Push the branch and tag to the correct remote. The repository currently has two remotes; confirm which one is authoritative before pushing.
- [ ] Back up the source and build artifacts somewhere outside Dropbox.

## 2. Version and release metadata

- [x] Set the version in `project.godot` and in every export preset.
- [x] Set the Windows file version and product version (`1.0.0.0`).
- [x] Set the macOS short version and bundle version (`1.0`).
- [x] Set the copyright and company fields for Windows and macOS (`2026 Tim Martin`).
- [x] Update the title/credits screen so it does not display an outdated year.
- [x] Update `README.md`: replace `RaCombo` with `Spherifactory`, add a short description, controls, build/run notes, and current credits.
- [x] Remove the stale `still to do` section from `README.md`; the listed sounds are already present.
- [x] Decide whether the default `user://` path is acceptable. Retained for 1.0 to preserve existing saves (no custom user directory).
- [x] Confirm `SAVE_FORMAT_VERSION` and `CAMPAIGN_FORMAT_VERSION` in `scripts/Global.gd` match the final data format (no schema change in this pass).
- [x] Confirm save, settings, custom-campaign, and screenshot paths are documented in `AGENTS.md`.

## 3. Build and export

> **Deferred:** actual exports, clean-machine installs, and platform QA are
> deferred until the configuration and content pass is complete. Configuration
> items completed in this pass are marked below.

### All platforms

- [x] Install matching Godot 3.6.2 export templates from the editor's export-template manager.
- [x] Open the project in Godot 3.6.2 and confirm the Output panel has no parser errors or missing-resource warnings.
- [ ] Export a release build, not a debug build.
- [x] Review export filters so dev/test scenes, `.pdn` source art, editor addons, and marketing/screenshot files are not shipped (`all_resources` plus `exclude_filter="addons/*"`; runtime asset cleanup deferred).
- [ ] Confirm `resources/campaign_data.json` is in the exported PCK. Launch the exported build and verify the built-in campaign is selectable.
- [ ] Confirm all 13 registered translations are present and switchable in the exported build.
- [ ] Confirm `Music.tscn` and `Sfx.tscn` autoloads work in the exported build.
- [ ] Confirm all audio files play in the exported build.
- [ ] Test with a brand-new user-data directory. Do not rely on dev saves or settings.
- [ ] Test with an existing dev save to ensure compatibility, or intentionally block it with a clear message.
- [ ] Record the build hash and version for each platform.

### Windows

- [x] Set the export path to `build/windows/Spherifactory.exe`.
- [x] Keep the 64-bit build unless a 32-bit build is explicitly required.
- [x] Include `resources/campaign_data.json` through the preset's non-resource include filter and use `all_resources` so dynamic gem/audio/translation resources are included.
- [ ] Confirm the `.pck` is included in the distribution, or enable embedded PCK and confirm the single executable works.
- [x] Set the Windows icon (`images/ico.ico`).
- [x] Fill in application metadata (file description, product name, versions, copyright).
- [x] Decide Windows code signing for 1.0: unsigned build; document the SmartScreen warning on the itch.io page.
- [ ] Build a zip containing the executable and `.pck` (or the embedded executable).
- [ ] Test on a clean Windows 10 or Windows 11 machine or VM with no Godot installed.
- [ ] Test windowed and fullscreen at 1280x720, 1600x900, 1920x1080, and 2560x1440.
- [ ] Test display scaling at 100%, 125%, and 150%.
- [ ] Test alt-tab, minimize/restore, sleep/resume, and multi-monitor behaviour.
- [ ] Confirm the game launches from a path containing spaces and non-ASCII characters.

### macOS (ad-hoc signing)

- [x] Create a macOS preset with a permanent bundle identifier (`com.timboe.spherifactory`).
- [x] Set the app name, category, version, short version, and copyright.
- [x] Set the macOS icon source (`images/ico.png`); Godot generates the `.icns`.
- [x] Use the standard Godot 3.6 macOS template (expected universal; verify the exported binary architectures during QA).
- [ ] Test the unsigned build first, then ad-hoc sign it on macOS:
  `codesign --force --deep --sign - "Spherifactory.app"`.
- [ ] Verify the signature: `codesign --verify --deep --strict --verbose=2 "Spherifactory.app"`.
- [ ] Package the `.app` with `ditto -c -k --keepParent "Spherifactory.app" "Spherifactory-macos.zip"` so permissions and symlinks are preserved.
- [ ] Run `spctl --assess --type execute --verbose=4 "Spherifactory.app"` and confirm it reports the expected rejection for an ad-hoc signed, non-notarized app. Do not treat that rejection as a build failure.
- [ ] Test the downloaded zip on a clean macOS user account. Document the right-click **Open** workaround and, if needed, `xattr -dr com.apple.quarantine "Spherifactory.app"`.
- [ ] Test on Intel and Apple Silicon if both are available.
- [ ] Confirm the build does not depend on files outside the `.app` bundle.
- [ ] Confirm the `.app` contains the `.pck` or embedded PCK and starts from Finder.

## 4. Content, localization, and legal

- [x] Remove the 27 junk `#VALUE!`/blank rows from `language/spherifactory_language_matrix.csv` (178 rows remain).
- [x] Remove the duplicate `ui_factory` key.
- [x] Remove unused `hint_*` keys (30 rows removed).
- [x] Register `language/spherifactory_language_matrix.zh_Hans_CN.translation` in `project.godot` and update the language menu metadata to `zh_Hans_CN`; remove the stale `zh.translation`. Existing `lang: "zh"` settings are migrated in `MainMenu.gd`.
- [x] Confirm every literal `tr("ui_...")` and scene `ui_*`/`tut_*` key used by the game exists in the CSV and regenerated translations (140 used keys checked; no true misses).
- [x] Decide that built-in campaign hints remain English-only for 1.0; note this on the store page.
- [ ] Check long German, Russian, and Polish strings for clipping in menus, buttons, save slots, and tutorial pages.
- [ ] Check Japanese, Korean, and Chinese glyph coverage using the Noto CJK font.
- [ ] Confirm the language selection persists after returning to the title screen and restarting.
- [x] Implement Q/E zoom (E zoom in, Q zoom out) through `ui_zoom_in`/`ui_zoom_out`; the tutorial text is now accurate.
- [ ] Verify Q/E and mouse-wheel zoom clamp at `min_zoom=0.1` and `max_zoom=2.0`, and confirm the trailer cinematic zoom still behaves.
- [x] Tighten camera panning so the view cannot extend beyond the `spacefield` background at maximum zoom-out.
- [ ] Verify camera pan limits at maximum zoom-out and at several aspect ratios.
- [x] Proofread the credits, licence text, and README (store copy is tracked in Section 6).
- [x] Verify that no third-party asset is shipped without its required attribution or licence text; the in-game credits now cover SFX and the remaining Flaticon/Noun Project contributors.
- [x] Confirm the source-code MIT licence and third-party asset licences are clearly separated in the README and in-game credits.

## 5. Functional QA

> **Deferred** until the exported builds are available.

Run these checks in the exported release build, not only in the editor. Use a fresh user-data directory for the first pass.

### Startup and menus

- [ ] Launch with no `settings.json`, `save_data.json`, or custom campaigns. The title screen opens without errors.
- [ ] Music starts and the default audio settings apply.
- [ ] New Game lists built-in and custom campaigns.
- [ ] Load Game is disabled when there are no saves and works when saves exist.
- [ ] Settings opens, every control responds, and Back saves changes.
- [ ] Language menu switches language immediately and persists.
- [ ] Credits opens, scrolls to the bottom, and Back returns to the main menu.
- [ ] Exit quits cleanly.
- [ ] Window title, icon, and boot splash are correct.

### Campaign

- [ ] Start the built-in campaign at level 1.
- [ ] Complete the tutorial flow for the first missions.
- [ ] Complete or force-advance every level 1-10 and confirm victory transitions.
- [ ] Confirm mission goal, remaining count, exported statistics, and mission text are correct.
- [ ] Confirm hints open and reveal correctly for every level.
- [ ] Confirm a finished campaign shows the victory screen and can return to the title.
- [ ] Start a level directly from the campaign selector and confirm the correct ring/lane/injector setup.
- [ ] Start a custom campaign and confirm its data loads.
- [ ] Confirm a custom campaign name that collides with a built-in campaign is rejected or skipped with a clear message.

### Sandbox

- [ ] Start sandbox mode.
- [ ] Change ring and lane counts.
- [ ] Place extractors, inserters, and factories.
- [ ] Change the pull direction.
- [ ] Inject resources.
- [ ] Save, load, and overwrite a sandbox save.
- [ ] Confirm the restored ring/lane counts and injectors are correct.
- [ ] Clear all and confirm the sandbox resets cleanly.

### Save/load and autosave

- [ ] Create a new save.
- [ ] Overwrite an existing save.
- [ ] Load a save from the title screen and from in-game.
- [ ] Delete a save and confirm the thumbnail is removed.
- [ ] Let autosave run and confirm it updates the autosave slot.
- [ ] Confirm save thumbnails are captured, upright, and correctly sized.
- [ ] Confirm timestamps and play time are correct.
- [ ] Test with a corrupt save file and confirm the game fails gracefully instead of crashing or silently losing data.
- [ ] Test with a save from an incompatible format version and confirm a clear message is shown.
- [ ] Test with a missing save thumbnail.
- [ ] Test with a read-only or full user-data directory if feasible.
- [ ] Confirm sandbox saves, campaign saves, and custom-campaign saves do not overwrite unrelated slots.

### Gameplay systems

- [ ] Extractor behavior, including the Sol ring and outermost ring.
- [ ] Inserter behavior and direction changes.
- [ ] Factory imports and exports.
- [ ] Transmutation at Sol.
- [ ] Ship spawning, movement, launch, and deposit.
- [ ] Ring selection, factory placement, rotation, and removal.
- [ ] Injection lane selection and resource hints.
- [ ] Pause, fast-forward, and outlines buttons.
- [ ] Ring diagnostics, building diagnostics, ship details, all-recipes view, and exported-resource view.
- [ ] Right-click cancels build/inject mode.
- [ ] Middle-mouse drag pans the camera.
- [ ] Mouse wheel zooms, and Q/E/WASD/arrow-key controls work.
- [ ] Confirm `T` does not start an unintended trailer sequence in the shipping build.
- [ ] Confirm no debug label, overlay, or console spam appears during normal play.
- [ ] Test with a gamepad if controller support is expected. If it is not supported, remove or document the joypad mappings.

### Audio

- [ ] Music tracks play and rotate without gaps or loops getting stuck.
- [ ] Victory, thud, click, no/error, and blip sounds play at the correct volume.
- [ ] Music, SFX, and beep sliders work independently and persist.
- [ ] Setting a slider to zero mutes the correct bus.
- [ ] Audio does not clip or stutter during fast-forward or heavy scenes.
- [ ] Audio resumes correctly after alt-tab, sleep, or focus loss.

### UI and display

- [ ] Test 1280x720, 1600x900, 1920x1080, 2560x1440, and an ultrawide aspect.
- [ ] Test windowed and fullscreen.
- [ ] Test display scaling at 100%, 125%, and 150%.
- [ ] Confirm no text is clipped in the longest localized strings.
- [ ] Confirm the UI remains usable after changing resolution while the game is running.
- [ ] Confirm the camera clamp and zoom limits behave correctly at each aspect ratio.
- [ ] Confirm the game window opens on-screen at startup and after fullscreen transitions.

### Stability

- [ ] Play for at least 30-60 minutes continuously, including autosaves.
- [ ] Leave the game idle through several autosaves.
- [ ] Confirm memory use is stable.
- [ ] Confirm the Output/log contains no repeating errors or warnings.
- [ ] Complete a full campaign run without using development shortcuts.

## 6. itch.io release

> **Deferred** until builds and functional QA are complete.

- [ ] Finalize the itch.io page: title, short description, long description, tags, pricing, and system requirements.
- [ ] Prepare cover image, screenshots, and a trailer or animated GIF. New marketing screenshots are required; the old development `ss.png` has been removed.
- [ ] Add credits, licence notices, support contact, and a privacy note if required.
- [ ] Create Windows and macOS channels.
- [ ] Install and log in to butler, then push the builds:
  `butler push build/windows USER/GAME:windows --userversion 1.0.0`
  `butler push build/macos USER/GAME:osx --userversion 1.0.0`
- [ ] Set the correct channel as the default download.
- [ ] Test downloading both builds from a logged-out browser.
- [ ] Install and launch both downloads on clean machines.
- [ ] Confirm the zip structure is understandable and does not contain dev files.
- [ ] Confirm the macOS Gatekeeper workaround is visible on the page.
- [ ] Schedule or publish the page only after every P0/P1 item is complete.
- [ ] Prepare release notes and a changelog.

## 7. Release day

> **Deferred** until the store page and final builds are ready.

- [ ] Freeze the final build and verify its hash.
- [ ] Publish the itch.io page.
- [ ] Verify both downloads work immediately after publication.
- [ ] Push the final source commit and tag.
- [ ] Create a release entry with version, build hashes, and known limitations.
- [ ] Announce the release.
- [ ] Keep a hotfix branch ready and back up the shipped artifacts.

## 8. Post-release

> **Deferred** until after launch.

- [ ] Monitor itch.io comments and crash reports for the first 72 hours.
- [ ] Triage save-compatibility and startup issues first.
- [ ] Keep old builds available for rollback.
- [ ] Plan a 1.0.x patch release for confirmed bugs.
- [ ] Start the Android tablet readiness track in Appendix A only after the desktop release is stable.

## Appendix A - Android tablet readiness (post-launch)

> **Deferred** until after the desktop release is stable.

This is not a blocker for the Windows/macOS release. It records the UI and platform work needed before an Android tablet build can be considered ready.

### Product decisions

- [ ] Confirm Android distribution: Google Play, itch.io APK, or both.
- [ ] Confirm landscape-only or rotation support.
- [ ] Confirm minimum Android version and tablet sizes.
- [ ] Confirm whether Android is a separate build target or a shared build with mobile-only UI.
- [ ] Confirm whether touch-only play must be possible without a mouse or keyboard.

### UI and input

- [ ] Fix `display/window/stretch/mode` to `"2d"` and test tablet resolution scaling.
- [ ] Set an explicit landscape/sensor-landscape orientation.
- [ ] Test `keep_width` on 16:10 and 4:3 tablets and add safe-area margins if needed.
- [ ] Decide whether the 1280x720 base resolution is sharp enough on high-DPI tablets, or raise the base resolution.
- [ ] Add a visible **Cancel** action for build/inject mode; right-click is not available on touch.
- [ ] Add on-screen zoom +/- controls or clearly document pinch zoom.
- [ ] Add a touch-accessible pause/menu action; do not rely on the Space key.
- [ ] Hide or adapt desktop-only **Fullscreen** and **Exit** controls.
- [ ] Add Android Back-button handling: open the menu, pause, or confirm exit instead of quitting abruptly.
- [ ] Pause and autosave on app focus loss or `NOTIFICATION_APPLICATION_PAUSED`.
- [ ] Increase touch targets to at least roughly 48dp where practical.
- [ ] Audit hover-only tooltips and highlights; ensure every action is discoverable by tap.
- [ ] Confirm the soft keyboard opens for campaign-editor LineEdit/TextEdit fields.
- [ ] Confirm clipboard copy/paste for custom campaigns works on Android.
- [ ] Replace keyboard/mouse tutorial text with touch-specific or input-neutral wording:
  - Drag to pan.
  - Pinch to zoom.
  - Tap to select and place.
  - Tap Cancel to leave build mode.
- [ ] Confirm no text refers to WASD, arrow keys, middle mouse, Q/E, or right-click in the tablet build.

### Build and store

- [ ] Set a permanent Android package ID.
- [ ] Create a release keystore and keep it out of source control.
- [ ] Configure separate debug and release signing.
- [ ] Build an AAB if targeting Google Play; build an APK for itch.io if needed.
- [ ] Set version code and version name.
- [ ] Add Android launcher icons and adaptive icons.
- [ ] Set the target API level required by the store.
- [ ] Decide whether arm64-only is sufficient or whether armeabi-v7a is still required.
- [ ] Test immersive mode and system bar behaviour.
- [ ] Prepare tablet screenshots, store listing, privacy policy, and content rating.
- [ ] Confirm the game is fully offline and requires no permissions beyond what is declared.

### Device QA

- [ ] Test a 10-11 inch 16:10 tablet.
- [ ] Test a 4:3 tablet if one is available.
- [ ] Test Android 11, 13, and 15 (or the oldest and newest supported versions).
- [ ] Test a low-end and a mid/high-end device.
- [ ] Test touch-only: no mouse, no keyboard.
- [ ] Test pinch zoom, drag pan, tap selection, build placement, and cancel.
- [ ] Test pause/resume, rotation, Back, and app kill/restart.
- [ ] Test save/autosave/restore on Android.
- [ ] Confirm stable frame rate and acceptable battery/heat.
- [ ] Confirm the campaign is completable on a tablet without a mouse or keyboard.

## Sign-off

| Check | Name | Date | Notes |
| --- | --- | --- | --- |
| Repo clean / tagged |  |  |  |
| Windows build verified |  |  |  |
| macOS build verified |  |  |  |
| Credits and licences verified |  |  |  |
| Store page verified |  |  |  |
| Release approved |  |  |  |
