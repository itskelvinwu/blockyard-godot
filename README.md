# Blockyard

Isometric restaurant tycoon for **Godot 4.3+**, built to ship on **iOS**.

Codigames-style dollhouse diner: connected rooms, parking lot, city traffic, staff, and a cash / build / upgrade loop.

## Open

1. Install [Godot 4.3](https://godotengine.org/download) (or newer 4.x).
2. Import this folder (`project.godot`).
3. Press Play. Portrait mobile viewport, isometric pan / pinch-zoom camera.

## iOS (App Store)

Export is already set up:

- Bundle id: `com.blockyard.diner`
- Min iOS: 15
- Renderer: Mobile (Forward Mobile)
- Orientation: portrait
- Architecture: arm64

On a Mac:

1. Godot → **Project → Export → iOS**
2. Fill in your Apple Team ID and provisioning profiles
3. Export the Xcode project
4. Archive in Xcode and submit with your Apple Developer account

Godot cannot upload to the App Store by itself. Xcode is required for the last step.

## Layout

```
project.godot
export_presets.cfg     iOS + Web
scenes/main.tscn
scripts/
  session.gd           cash, gems, builds, save
  map_data.gd          Map 1 — Corner Diner
  world.gd             rooms, walls, city, traffic
  character.gd / car.gd
  camera_rig.gd
  hud.gd
```

Map units are meters, Y-up, so this matches the live web preview of the same diner.
