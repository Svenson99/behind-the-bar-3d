# Behind the Bar 3D

Native **Godot 4.4.1** first-person Android game prototype, not a web wrapper. Walk around a low-poly 3D pub, look through the bartender's eyes, pick up bottles, aim and pour measured quantities into a glass, jigger or shaker, then serve a customer. Five recipes, practice, timed shifts, quality scores, tips and local career saves.

## Build and install using only your phone

1. Open this repository's **Actions** tab in your phone browser while signed into GitHub.
2. Select **Build Android APK**, then **Run workflow**, select `main`, and confirm. If GitHub asks to enable Actions, review and enable it for this repository first.
3. Wait for the run to finish. Green means import, tests, APK export and signature verification succeeded. Red means no verified APK: open the failed step and share its log.
4. Open the completed run and download **Behind-the-Bar-3D-Android** under **Artifacts**. If the mobile view hides this section, use your browser's desktop-site mode.
5. Extract the ZIP using your phone's Files app. Open **Behind-the-Bar-3D.apk** and, if requested, allow your Files app to install this specific trusted test build.

The workflow is manual only: pushing files does not start builds. It has a 20-minute limit, uses standard Ubuntu runners, and retains the APK for seven days. Public standard-runner usage is normally free; check your account allowance/budget before using it after making the repository private. No paid runner or service is configured.

**Current status:** Source and cloud workflow supplied. No successful Godot runtime test, cloud build, APK installation or device performance test has yet been observed. The local authoring environment did not have Godot, and downloading it timed out. Do not mistake source upload for a completed APK.

## Controls

- Left pad: move. Drag the exposed 3D world to look around.
- Centre crosshair: aim at a labelled object, then **Pick / use**.
- Pick a bottle, aim at **GLASS**, **JIGGER** or **SHAKER**, then **hold POUR**. Releasing stops it. Flow is 20 ml/sec. Watch the displayed amounts.
- The jigger holds 50 ml; excess spills. Pick the jigger up, aim at glass/shaker and press Pour to empty it.
- Hold the shaker, aim at **ICE**, and Use to add ice to it. With a filled shaker held, tap **Shake / stir** then drag repeatedly over the world. Aim at the glass and Pour to strain into it.
- To stir, set down your item, aim at the filled glass and tap **Shake / stir**, then draw three circles around the crosshair. Shaking requires repeated back-and-forth swipes; progress is shown on screen.
- Aim at **ICE** and Use to add ice to the glass when not holding the shaker.
- Aim at **GARNISH** and Use to cycle lime/orange/olive. **Glass type** switches between a highball and a stemmed coupe.
- Pick up the finished **GLASS**, aim at **CUSTOMER**, and Use to serve.
- **Set down** returns the held vessel to its station. **Discard drink** clears ingredients without resetting career progress.
- Desktop development: WASD to move, left-drag world to look, E to use, Escape to pause.

Practice is untimed and shows required quantities. Regular shifts last three minutes, with 90 seconds of patience per customer. The shift clock continues through order feedback until paused. Quality rewards ingredient identity/amounts, glass, use of ice, technique and garnish. XP and tips save locally after each order and shift. Pausing or backgrounding cancels active pours.

## Scope and limitations

One playable venue: **The Copper Fox**. Qualification for future venues at 200 XP is a career milestone, not an implemented second venue. The game uses original procedural low-poly geometry, not finished character animation or photorealistic assets. No full fluid simulation, temperature/dilution simulation, sound, haptics, ads, login or multiplayer. No network permission is requested. Android ARM64 only.

Every cloud run currently generates a fresh **temporary debug signing key**. A later build may require uninstalling the earlier app first, which deletes local progress. Stable signing for updates should be configured privately before regular distribution. No signing key or credentials are committed, and test builds are not Play Store releases.

## Development

Open `project.godot` in Godot 4.4.1 (standard, not .NET). Use the Compatibility renderer. No asset downloads or plugins are required for gameplay.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_drink.gd
godot --headless --path . --script tests/smoke.gd
```

The workflow runs these checks before exporting. Headless smoke tests do not establish real touch performance or visual quality; inspect an installed APK on an Android phone before calling the game tested.

References: [Godot Android export requirements](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html), [GitHub Actions billing](https://docs.github.com/en/actions/concepts/billing-and-usage).
