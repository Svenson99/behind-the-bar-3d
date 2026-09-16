"""Configure the disposable CI runner's Godot 4.4 Android export paths."""
import json
import os
from pathlib import Path

config_root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
settings = config_root / "godot" / "editor_settings-4.4.tres"
settings.parent.mkdir(parents=True, exist_ok=True)
settings.write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    + 'export/android/android_sdk_path = ' + json.dumps(os.environ["ANDROID_HOME"]) + '\n'
    + 'export/android/java_sdk_path = ' + json.dumps(os.environ["JAVA_HOME"]) + '\n',
    encoding="utf-8",
)
print("Configured Godot Android SDK and Java paths")
