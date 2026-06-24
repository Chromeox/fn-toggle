#!/usr/bin/env bash
#
# toggle-function-keys.sh
#
# Toggle macOS function-key behavior:
#   ON  = F1–F12 act as standard function keys
#   OFF = F1–F12 act as media / hardware keys (brightness, volume, etc.)
#
# Flips the global `com.apple.keyboard.fnState` preference, applies it live
# (no logout required), and shows a notification with the new state.
#
set -uo pipefail

# Read the current state; default to 0 (media keys) if it was never set.
current=$(defaults read -g com.apple.keyboard.fnState 2>/dev/null || echo 0)

# Flip it. (Avoid `$(( ! current ))` — that arithmetic returns exit code 1
# when the result is 0, which trips up `set -e`.)
if [ "$current" = "1" ]; then
  new=0
else
  new=1
fi

defaults write -g com.apple.keyboard.fnState -int "$new"

# Apply immediately without a logout. This private framework helper has been
# the stable way to do this for many macOS releases.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Notify (different title + sound per state so you can tell by ear).
if [ "$new" -eq 1 ]; then
  osascript -e 'display notification "Standard F1–F12 keys" with title "Function Keys: ON" sound name "Tink"'
else
  osascript -e 'display notification "Media / hardware keys" with title "Function Keys: OFF" sound name "Pop"'
fi
