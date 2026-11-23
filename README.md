# SCRAPFALL 2: ROAD WAR

Sequel to SCRAPFALL. Low-poly 3D (Godot 4.7.2, `gl_compatibility`). Design: `../scrapfall/docs/superpowers/specs/2026-11-23-scrapfall2-road-war-design.md`.

## Play
Drive by day (A/D or touch halves to steer, SPACE/BOOST to ram), stop at scrap yards (E/STOP) and fight on foot
(WASD + right-drag look + click, or stick + drag + FIRE), park at night and build guns/walls (tap, or 1/2 + click).

## Tests
`python tools/test.py` (all) or `python tools/test.py road` (files whose name contains "road").

## Dev flags (after `--`)
`--shot=<png> --shot-after=<frames>` screenshot and quit, `--cam=<0|1|2>`, `--night` (dusk in 0.5 s, 60 scrap),
`--stop` (a scrap yard right ahead, you get out), `--invincible`.

## Release
Bump `version/code` + `version/name` in `export_presets.cfg`, tag `vX.Y.Z`, push the tag: GitHub Actions builds
`SCRAPFALL2.apk` + `SCRAPFALL2.exe` onto the release (needs secrets `ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_ALIAS`,
`ANDROID_KEYSTORE_PASSWORD`).
