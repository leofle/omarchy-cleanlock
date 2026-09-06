# Clean Lock (`omarchy-cleanlock`)

Lock your **keyboard** and/or **trackpad** so you can wipe them without typing gibberish or moving the cursor.

**Plugin ID:** `io.github.leofle.cleanlock`

## Install

Omarchy only shows a bar icon for **enabled** plugins. Enabling does **not** lock anything — it only loads the widget so you can click it when you want to clean.

```bash
omarchy plugin add https://github.com/leofle/omarchy-cleanlock.git --enable
omarchy restart shell
```

Or from a local checkout (copies into `~/.config/omarchy/plugins/`, enables the bar icon, and links `cleanlock` on your PATH):

```bash
~/Projects/omarchy-cleanlock/sync-install.sh
```

If you already added the plugin without `--enable`:

```bash
omarchy plugin enable io.github.leofle.cleanlock --section right
omarchy restart shell
```

## Unlock

Hold the **Super / Windows** key for **5 seconds**.

(Right Super also works on dual-Super keyboards. Copilot-key PCs are fine — you do not need Right Super.)

Detected from the raw input device, so it still works after Hyprland has disabled the keyboard.

## Safety

While Clean Lock is active:

- **Idle sleep/lock is inhibited** (so wiping keys cannot idle-lock or hibernate the machine)
- If the **session locks** or the system is about to **sleep/hibernate** anyway, inputs are **force-unlocked** so you can type your password

## Bar widget

1. Click the keyboard icon on the bar
2. Choose **Keyboard**, **Trackpad**, or **Both**
3. Clean away
4. Hold Super / Windows for 5s (or click **Unlock now** if the trackpad is still enabled)

## CLI

```bash
cleanlock lock-keyboard
cleanlock lock-trackpad
cleanlock lock-both
cleanlock unlock
cleanlock status
cleanlock diagnose
```

(`cleanlock` is the script under `bin/`; `sync-install.sh` links it to `~/.local/bin`.)

## Remove

```bash
omarchy plugin disable io.github.leofle.cleanlock
omarchy plugin remove io.github.leofle.cleanlock
omarchy restart shell
rm -f ~/.local/bin/cleanlock
rm -rf ~/.local/state/omarchy/cleanlock
```

No user Hyprland or shell config is overwritten by this plugin.

## License

MIT
