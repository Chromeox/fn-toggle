# fn-toggle

Toggle macOS function-key behavior with a global hotkey.

Press **⌃⌥⌘F** to flip your `F1`–`F12` keys between:

- **ON** — standard function keys (`F1`, `F2`, … `F12`)
- **OFF** — media / hardware keys (brightness, volume, playback, …)

A notification tells you which mode you just switched to, with a distinct sound for each.

This does exactly what the **System Settings → Keyboard → "Use F1, F2, etc. keys as standard function keys"** checkbox does — but bound to a key you can hit from anywhere, in any app.

---

## Why this exists

macOS has no built-in shortcut for that checkbox. The common workaround is an Automator/Shortcuts Quick Action, but binding it to a *global* hotkey is unreliable (the native "Run with" hotkey often silently fails). `fn-toggle` skips all that: a tiny shell script driven by [`skhd`](https://github.com/koekeishiya/skhd), a battle-tested hotkey daemon. No Automator, no Shortcuts.app, no GUI clicking.

## How it works

```
You press ⌃⌥⌘F
      │
      ▼
   skhd (background hotkey daemon)
      │
      ▼
 toggle-function-keys.sh
      │  flips com.apple.keyboard.fnState (0 ⇄ 1)
      │  applies it live via activateSettings -u
      ▼
 notification: "Function Keys: ON / OFF"
```

The toggle is a plain `defaults write` to the global `com.apple.keyboard.fnState` preference, applied immediately (no logout) through Apple's `activateSettings` helper.

## Requirements

- macOS
- [Homebrew](https://brew.sh) (the installer uses it to install `skhd`)

## Install

```bash
git clone https://github.com/Chromeox/fn-toggle.git
cd fn-toggle
./install.sh
```

The installer will:

1. Install `skhd` via Homebrew if you don't have it.
2. Copy the toggle script to `~/.config/fn-toggle/`.
3. Add the hotkey to your `~/.skhdrc` (safely — it won't clobber an existing config).
4. Start the `skhd` background service.

### One manual step: Accessibility access

`skhd` needs permission to listen for the global hotkey. macOS requires you to grant this by hand:

1. **System Settings → Privacy & Security → Accessibility**
2. If **skhd** is listed, switch it **ON**.
3. If it's not listed, click **➕**, press **⌘⇧G**, paste the path the installer printed (e.g. `/opt/homebrew/bin/skhd`), open it, then switch it **ON**.
4. Run `skhd --restart-service`.

That's it — press **⌃⌥⌘F** and your function keys flip.

## Usage

Just press **⌃⌥⌘F** any time. A banner confirms the new state.

You can also run the toggle directly, without the hotkey:

```bash
~/.config/fn-toggle/toggle-function-keys.sh
```

## Customizing the hotkey

Edit `~/.skhdrc`, change the `ctrl + alt + cmd - f` part to whatever you like, then:

```bash
skhd --restart-service
```

`skhd` modifier names: `cmd`, `alt` (Option), `ctrl`, `shift`, `fn`. Example — make it ⌃⇧F12:

```
ctrl + shift - f12 : ~/.config/fn-toggle/toggle-function-keys.sh
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| Hotkey does nothing | Grant skhd **Accessibility** access (see above), then `skhd --restart-service`. |
| `skhd: must be run with accessibility access! abort..` in logs | Same as above — the permission isn't granted yet. |
| Toggle works but **no notification banner** | **System Settings → Notifications → Script Editor** → allow notifications. Also check you're not in a Focus / Do Not Disturb mode. |
| Hotkey conflicts with another app | Change the combo in `~/.skhdrc` and restart the service. |

skhd logs live at `/tmp/skhd_<user>.out.log` and `/tmp/skhd_<user>.err.log`.

## Uninstall

```bash
./uninstall.sh
```

This removes the hotkey and the installed script. It leaves `skhd` installed (you might use it for other hotkeys); remove it with `brew uninstall skhd`.

## License

[MIT](LICENSE)
