# Native 3D rebuild

Approved direction: real 3D first-person bartender game, installable Android APK, public GitHub repository for now. Replaces—not packages—the rejected HTML prototype.

## First build
Godot 4.4.1, GDScript, Compatibility renderer, landscape Android arm64. A procedurally modelled pub, physical 3D counter and bottles, first-person movement and look, ray-based object selection, a visible held bottle, manual timed pouring and animated liquid stream. Glass, 50 ml jigger and shaker are distinct containers. Shake with repeated drag gestures; stir manually. Select garnish and glass type. Serve to the customer, receive quality feedback, tips and XP. Three-minute shifts and untimed practice. Career venues beyond the first pub are clearly labelled future content.

No account, monetization, Internet permission, analytics or external assets. Saved career data stays on device. This is a low-poly first playable, not a photorealistic finished game.

## Implementation plan
1. Write executable Godot tests for volume/overflow, jigger transfer, ingredient score, invalid amounts and duplicate service; implement scripts/drink.gd and scripts/career.gd.
2. Generate the pub using mesh helpers in scripts/world.gd. Add colliders and object metadata. Add first-person controls and camera in scripts/main.gd with independent UI in scripts/hud.gd.
3. Wire timed pouring, shake gestures, pause/background protection, practice, shifts and persistent XP to the actual 3D objects.
4. Add tests/smoke.gd that instantiates the real scene and asserts camera, world and UI readiness.
5. Manual-only GitHub Actions workflow: download pinned Godot and matching export templates with checksums, import, execute tests, headless smoke, export debug APK, verify APK signature, upload artifact with seven-day retention. Limit runtime to 20 minutes; no push-triggered builds.
6. Publish files without overwriting unrelated user work; report exact verification status. First online build and Android device test remain necessary when local tooling cannot run.

## Acceptance
The APK must be compiled successfully, then installed and exercised on an Android device before being called tested or finished. A repository or workflow alone is not the APK. No automatic paid build is authorized.
