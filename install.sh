#!/usr/bin/env bash
#
# install.sh — set up the ⌃⌥⌘F function-key toggle hotkey.
#
# Installs skhd (if needed), copies the toggle script into place, wires the
# hotkey into ~/.skhdrc safely, and starts the background service. The only
# step it can't automate is granting skhd Accessibility access (macOS requires
# a human click for that) — it prints instructions at the end.
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.config/fn-toggle"
SCRIPT_NAME="toggle-function-keys.sh"
SKHDRC="$HOME/.skhdrc"

# Change this if ⌃⌥⌘F clashes with something on your machine.
HOTKEY="ctrl + alt + cmd - f"

echo "==> Installing fn-toggle"

# 1. Locate Homebrew.
if command -v brew >/dev/null 2>&1; then
  BREW="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
  BREW=/opt/homebrew/bin/brew          # Apple Silicon
elif [ -x /usr/local/bin/brew ]; then
  BREW=/usr/local/bin/brew             # Intel
else
  echo "Error: Homebrew not found. Install it from https://brew.sh and re-run." >&2
  exit 1
fi

# 2. Install skhd if it isn't already.
if ! "$BREW" list skhd >/dev/null 2>&1; then
  echo "==> Installing skhd via Homebrew..."
  "$BREW" install koekeishiya/formulae/skhd
else
  echo "==> skhd already installed."
fi
SKHD="$("$BREW" --prefix)/bin/skhd"

# 3. Copy the toggle script to a stable location.
mkdir -p "$INSTALL_DIR"
cp "$REPO_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "==> Installed script -> $INSTALL_DIR/$SCRIPT_NAME"

# 4. Wire the hotkey into ~/.skhdrc without clobbering anything.
CONFIG_LINE="$HOTKEY : $INSTALL_DIR/$SCRIPT_NAME"
touch "$SKHDRC"
if grep -qF "$INSTALL_DIR/$SCRIPT_NAME" "$SKHDRC"; then
  echo "==> Hotkey already configured in $SKHDRC (skipping)."
elif grep -qF "$HOTKEY" "$SKHDRC"; then
  echo "!!  $SKHDRC already binds '$HOTKEY' to something else."
  echo "    Edit it manually, or change HOTKEY at the top of this script. Desired line:"
  echo "      $CONFIG_LINE"
else
  printf '\n# fn-toggle: switch F1–F12 <-> media keys\n%s\n' "$CONFIG_LINE" >> "$SKHDRC"
  echo "==> Added hotkey to $SKHDRC ($HOTKEY)"
fi

# 5. Start / reload the service.
"$SKHD" --restart-service >/dev/null 2>&1 || "$SKHD" --start-service >/dev/null 2>&1 || true
echo "==> skhd service started."

# 6. The one manual step.
echo ""
echo "────────────────────────────────────────────────────────"
echo "ONE MANUAL STEP — grant skhd Accessibility access"
echo "────────────────────────────────────────────────────────"
echo "skhd needs permission to listen for the global hotkey."
echo ""
echo "  System Settings → Privacy & Security → Accessibility"
echo "    • If 'skhd' is listed, switch it ON."
echo "    • If not, click +, press Cmd+Shift+G, paste this path:"
echo "          $SKHD"
echo "      open it, then switch it ON."
echo ""
echo "  Then run:  skhd --restart-service"
echo ""
echo "Default hotkey: Ctrl + Option + Command + F"
echo "Change it by editing ~/.skhdrc then: skhd --restart-service"
echo "────────────────────────────────────────────────────────"
