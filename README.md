# Behind the Bar 3D

Native **Godot 4.4.1** first-person Android bartending game. Version 0.2.0 adds four simultaneous seated customers, continuous service, physically aimed pouring, stock and waste costs, dropped glass physics, sound, recipes and three unlockable venue settings.

## Build and install using only your phone

1. Open this repository's **Actions** tab in your phone browser while signed into GitHub.
2. Select **Build Android APK**, then **Run workflow**, select `main`, and confirm. If GitHub asks to enable Actions, review and enable it for this repository first.
3. Wait for the run to finish. Green means import, tests, APK export and signature verification succeeded. Red means no verified APK: open the failed step and share its log.
4. Open the completed run and download **Behind-the-Bar-3D-Android** under **Artifacts**. If the mobile view hides this section, use your browser's desktop-site mode.
5. Extract the ZIP using your phone's Files app. Open **Behind-the-Bar-3D.apk** and, if requested, allow your Files app to install this specific trusted test build.

The workflow is manual only: pushing files does not start builds. It has a 20-minute limit, uses standard Ubuntu runners, and retains the APK for seven days. Public standard-runner usage is normally free; check your account allowance/budget before using it after making the repository private. No paid runner or service is configured.

**Validation:** Previous APKs have built and run on Android. Version 0.2.0 is covered by headless scene, touch, customer and pouring integration tests. Its graphics, audio mix and performance still require device testing. See the latest Actions run for the actual APK build status.

## Controls and service

- Left pad: walk. Drag the world: look. Crosshair and **Pick / use** pick up bottles and tools.
- Select a seat ticket to display that customer's recipe. Each of four seats has its own arrival, order, patience, drinking and departure state. Serving one customer does not stop the others.
- Hold **POUR** to tilt the bottle. While holding, use another finger to drag the bottle over the container. Green landing marker means the stream crosses an opening; red means it misses. Move closer to the counter if needed. Release to stop.
- Flow follows an initial velocity and gravity, tested against circular container openings and solid world geometry. There is no attraction to the selected glass. The stock decreases on missed pours too.
- Bottles start each shift with 750 ml. Flow is 28 ml/s. Jigger: 50 ml; highball: 350 ml; coupe: 150 ml. Overflow spills. Decant the jigger or shaker gradually with the same pouring controls.
- Add ice by aiming at **ICE** and using it. Hold a filled shaker, tap **Shake / stir**, and swipe back and forth. For stirring, aim at a filled glass and draw circles after tapping the mixing button.
- **GARNISH** cycles lime/orange/olive. **Glass type** chooses highball/coupe. Pick up the completed glass and use the actual seated customer to serve. It is judged against that customer's order, even if a different ticket is selected.
- **Set down** safely returns the item to its station. **Drop glass** releases a rigid body, breaks it on contact and costs €2.50 plus contents. **Discard drink** empties the containers and charges waste.
- **Recipes** pauses the shift and opens the recipe book. Pause/settings include sound and music toggles, saved locally.
- Desktop: WASD, left-drag, E, Escape.

## Career

Shifts last three minutes. Waiting patrons leave after their patience runs out. Wrong ingredients, amounts, glass, garnish and technique reduce quality/tips. Waste costs €0.012/ml; damage costs €2.50/glass. Net positive tips are banked at shift end. Leaving a shift early forfeits that shift's tips. Career XP is saved after serving; practice never awards XP. Menu shows banked tips and completed shifts.

The Copper Fox is available immediately. Velvet Lounge unlocks at 120 XP; Skyline Terrace at 300 XP. These use the same bar workstation with different decor, lighting, ambient colors and customer pace/tip rewards. Lounge has velvet dividers and a chandelier; terrace opens the ceiling and rear view to a skyline and balcony. Practice is untimed.

## Visuals and simulation limits

Original procedural geometry, wood-grain textures, polished glass/metal materials, shadows, architectural detail, seated characters and original synthesized audio are included without external assets. This is **not photorealistic character art**. Characters use simple procedural poses, not a motion-captured walk/sit rig. Venue workstations share their layout.

Pouring uses ballistic collision/catch calculations and metered volume transfer, not a full fluid solver. Glass drops and fragments use Godot rigid-body physics. Temperature, dilution, wet surface cleanup, free placement of every object, crowd navigation and full character animation are not implemented. Sounds are synthesized, not recordings of a real bar. Android ARM64; offline; no ads, login or multiplayer.

Every cloud run currently generates a fresh **temporary debug signing key**. A later build may require uninstalling the earlier app first, which deletes local progress. Stable signing for updates should be configured privately before regular distribution. No signing key or credentials are committed, and test builds are not Play Store releases.

## Development

Open `project.godot` in Godot 4.4.1 (standard, not .NET). Use the Compatibility renderer. No asset downloads or plugins are required for gameplay.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_drink.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/touch_input.gd
godot --headless --path . --script tests/pour_effect.gd
godot --headless --path . --script tests/shift.gd
godot --headless --path . --script tests/service_integration.gd
```

The workflow runs these checks before exporting. Headless smoke tests do not establish real touch performance or visual quality; inspect an installed APK on an Android phone before calling the game tested.

References: [Godot Android export requirements](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html), [GitHub Actions billing](https://docs.github.com/en/actions/concepts/billing-and-usage).
