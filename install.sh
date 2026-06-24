#!/usr/bin/env bash
#
# install.sh — set up the ⌃⌥⌘F function-key toggle hotkey.
#
# Automates everything that can be automated:
#   • installs Homebrew (with your OK) if it's missing
#   • installs skhd
#   • copies the toggle script into place
#   • wires the hotkey into ~/.skhdrc (without clobbering an existing config)
#   • starts the background service
#   • opens the Accessibility settings pane and copies the skhd path to your
#     clipboard, then waits and verifies the grant actually took effect
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.config/fn-toggle"
SCRIPT_NAME="toggle-function-keys.sh"
SKHDRC="$HOME/.skhdrc"

# Change this if ⌃⌥⌘F clashes with something on your machine.
HOTKEY="ctrl + alt + cmd - f"

ERR_LOG="/tmp/skhd_$(whoami).err.log"

echo "==> Installing fn-toggle"

# ── 1. Homebrew ─────────────────────────────────────────────────────────────
find_brew() {
  if command -v brew >/dev/null 2>&1; then command -v brew
  elif [ -x /opt/homebrew/bin/brew ]; then echo /opt/homebrew/bin/brew   # Apple Silicon
  elif [ -x /usr/local/bin/brew ]; then echo /usr/local/bin/brew         # Intel
  fi
}

BREW="$(find_brew)"
if [ -z "$BREW" ]; then
  echo "==> Homebrew isn't installed."
  printf "    Install it now? This runs Homebrew's official installer. [Y/n] "
  read -r reply </dev/tty 2>/dev/null || reply="n"
  case "${reply:-Y}" in
    [Nn]*)
      echo "    Skipping. Install Homebrew from https://brew.sh then re-run ./install.sh" >&2
      exit 1 ;;
    *)
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Make brew available in this shell for Apple Silicon's default prefix.
      [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      BREW="$(find_brew)"
      [ -z "$BREW" ] && { echo "Homebrew install didn't complete; re-run ./install.sh" >&2; exit 1; } ;;
  esac
fi

# ── 2. skhd ─────────────────────────────────────────────────────────────────
if ! "$BREW" list skhd >/dev/null 2>&1; then
  echo "==> Installing skhd via Homebrew..."
  "$BREW" install koekeishiya/formulae/skhd
else
  echo "==> skhd already installed."
fi
SKHD="$("$BREW" --prefix)/bin/skhd"

# ── 3. Install the toggle script ────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
cp "$REPO_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "==> Installed script -> $INSTALL_DIR/$SCRIPT_NAME"

# ── 4. Wire the hotkey into ~/.skhdrc (safely) ──────────────────────────────
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

# ── 5. Accessibility: detect, guide, verify ─────────────────────────────────
# skhd aborts and logs "must be run with accessibility access!" on launch when
# it lacks the grant. We detect that to know whether access is in place.
skhd_has_access() {
  local before after
  before=$(wc -l < "$ERR_LOG" 2>/dev/null || echo 0)
  "$SKHD" --restart-service >/dev/null 2>&1 || "$SKHD" --start-service >/dev/null 2>&1 || true
  sleep 2
  after=$(wc -l < "$ERR_LOG" 2>/dev/null || echo 0)
  # Access is good if skhd is alive AND it didn't log new abort lines.
  pgrep -x skhd >/dev/null 2>&1 && [ "$after" -le "$before" ]
}

echo "==> Starting skhd and checking Accessibility access..."
if skhd_has_access; then
  echo "==> ✓ Accessibility already granted — skhd is running."
else
  echo ""
  echo "────────────────────────────────────────────────────────"
  echo "ACCESSIBILITY ACCESS NEEDED (one click, one time)"
  echo "────────────────────────────────────────────────────────"
  # Copy the path so the user can just paste it, and open the exact pane.
  printf '%s' "$SKHD" | pbcopy 2>/dev/null \
    && echo "  • The skhd path is on your clipboard (⌘V to paste):" \
    || echo "  • skhd path:"
  echo "        $SKHD"
  echo "  • Opening: System Settings → Privacy & Security → Accessibility"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
  echo ""
  echo "  In that pane:  add skhd with +  (⌘⇧G, paste, Open), then switch it ON."
  echo ""
  printf "  Waiting for the grant"
  granted=false
  for _ in $(seq 1 40); do          # up to ~90s
    if skhd_has_access; then granted=true; break; fi
    printf "."
  done
  echo ""
  if $granted; then
    echo "==> ✓ Access granted — skhd is running."
  else
    echo "!!  Still not detected. Grant skhd Accessibility access, then run:"
    echo "      skhd --restart-service"
  fi
fi

# ── 6. Done ─────────────────────────────────────────────────────────────────
echo ""
echo "Setup complete. Press  Ctrl + Option + Command + F  to toggle your F-keys."
echo "Change the hotkey by editing ~/.skhdrc, then: skhd --restart-service"
