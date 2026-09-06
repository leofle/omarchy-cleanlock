# Clean Lock (`omarchy-cleanlock`)

Lock your **keyboard** and/or **trackpad** so you can wipe them without typing gibberish or moving the cursor.

## Install

```bash
omarchy plugin add https://github.com/leofle/omarchy-cleanlock.git --enable
```

Or from a local checkout:

```bash
mkdir -p ~/.config/omarchy/plugins
ln -sfn ~/Projects/omarchy-cleanlock ~/.config/omarchy/plugins/cleanlock
omarchy plugin enable cleanlock --section right
omarchy restart shell
```

## Unlock

Hold **Left Super + Right Super** together for **5 seconds**.

Detected from the raw input device, so it still works after Hyprland has disabled the keyboard.

## Bar widget

1. Click the keyboard icon on the bar  
2. Choose **Keyboard**, **Trackpad**, or **Both**  
3. Clean away  
4. Hold both Super keys for 5s (or click **Unlock now** if the trackpad is still enabled)

## CLI

```bash
cleanlock lock-keyboard
cleanlock lock-trackpad
cleanlock lock-both
cleanlock unlock
cleanlock status
```

(`cleanlock` is the script under `bin/`; symlink it to `~/.local/bin` if you want it on your PATH.)

## License

MIT
