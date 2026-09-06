# Clean Lock (`omarchy-cleanlock`)

Lock your **keyboard** and/or **trackpad** so you can wipe them without typing gibberish or moving the cursor.

**Plugin ID:** `io.github.leofle.cleanlock`

## Install

```bash
omarchy plugin add https://github.com/leofle/omarchy-cleanlock.git --enable
omarchy restart shell
```

Or from a local checkout (Omarchy requires a real copy, not a symlink):

```bash
~/Projects/omarchy-cleanlock/sync-install.sh
```

## Unlock

Hold for **5 seconds**:

- **Left Super + Right Super** together (Mac / dual-Super keyboards), or
- **Windows (Left Super) + Copilot**: hold **Win**, tap **Copilot** once, keep holding **Win** for 5s

(The Copilot key usually sends a short Meta+Shift+F23 pulse, so it is latched while Win stays down.)

Detected from the raw input device, so it still works after Hyprland has disabled the keyboard.

## Safety

While Clean Lock is active:

- **Idle sleep/lock is inhibited** (so wiping keys cannot idle-lock or hibernate the machine)
- If the **session locks** or the system is about to **sleep/hibernate** anyway, inputs are **force-unlocked** so you can type your password

## Bar widget

1. Click the keyboard icon on the bar
2. Choose **Keyboard**, **Trackpad**, or **Both**
3. Clean away
4. Hold both Super keys for 5s — or Win + Copilot as above (or click **Unlock now** if the trackpad is still enabled)

## CLI

```bash
cleanlock lock-keyboard
cleanlock lock-trackpad
cleanlock lock-both
cleanlock unlock
cleanlock status
```

(`cleanlock` is the script under `bin/`; the install sync links it to `~/.local/bin`.)

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
