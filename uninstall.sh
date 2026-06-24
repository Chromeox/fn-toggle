#!/usr/bin/env bash
#
# uninstall.sh — remove the fn-toggle hotkey and script.
#
# Leaves skhd itself installed (you may use it for other hotkeys). To remove
# skhd entirely:  brew uninstall skhd
#
set -uo pipefail

INSTALL_DIR="$HOME/.config/fn-toggle"
SKHDRC="$HOME/.skhdrc"
SCRIPT_PATH="$INSTALL_DIR/toggle-function-keys.sh"

# Strip the fn-toggle comment + binding lines from ~/.skhdrc.
if [ -f "$SKHDRC" ]; then
  tmp="$(mktemp)"
  grep -v -e "fn-toggle" -e "$SCRIPT_PATH" "$SKHDRC" > "$tmp" || true
  mv "$tmp" "$SKHDRC"
  echo "==> Removed fn-toggle hotkey from $SKHDRC"
fi

# Remove the installed script.
rm -rf "$INSTALL_DIR"
echo "==> Removed $INSTALL_DIR"

# Reload skhd so the change takes effect.
if command -v skhd >/dev/null 2>&1; then
  skhd --restart-service >/dev/null 2>&1 || true
  echo "==> Reloaded skhd."
fi

echo ""
echo "Done. skhd is still installed (run 'brew uninstall skhd' to remove it)."
echo "Your keyboard's current F-key mode is unchanged."
