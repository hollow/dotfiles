#!/usr/bin/env zsh
#
# macOS defaults — non-default settings
#
# Apply:  ./macos/defaults.sh
# Review: ./macos/defaults.sh --dry-run
#
# Some changes require a logout/restart to take full effect.
# Affected services (Dock, Finder, etc.) are restarted at the end.
#

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

w() {
  if $DRY_RUN; then
    echo "[dry-run] defaults write $*"
  else
    defaults write "$@"
  fi
}

echo "==> Applying macOS defaults…"
$DRY_RUN && echo "    (dry-run mode — no changes will be made)"
echo ""

# ─── Appearance ───────────────────────────────────────────

echo "--- Appearance"

# Dark mode
w NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Disable transparency (windows, menu bar)
w com.apple.Accessibility reduceTransparency -bool true

# Double-click title bar: Maximize (instead of minimize)
w NSGlobalDomain AppleActionOnDoubleClick -string "Maximize"

# ─── Dock ─────────────────────────────────────────────────

echo "--- Dock"

# Auto-hide the Dock
w com.apple.dock autohide -bool true

# Remove all pinned apps from the Dock (start clean)
w com.apple.dock persistent-apps -array

# Don't show recent applications in Dock
w com.apple.dock show-recents -bool false

# ─── Window Manager ──────────────────────────────────────

echo "--- Window Manager"

# No gaps between tiled windows
w com.apple.WindowManager EnableTiledWindowMargins -bool false

# Click desktop to show desktop: only in Stage Manager (hide in standard)
w com.apple.WindowManager HideDesktop -bool true

# Hide desktop icons
w com.apple.WindowManager StandardHideDesktopIcons -bool true

# Hide widgets on desktop
w com.apple.WindowManager StandardHideWidgets -bool true
w com.apple.WindowManager StageManagerHideWidgets -bool true

# Disable window tiling by dragging to screen edges
w com.apple.WindowManager EnableTilingByEdgeDrag -bool false
w com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

# ─── Finder ───────────────────────────────────────────────

echo "--- Finder"

# Default to list view in all windows
# Nlsv = list, icnv = icon, clmv = column, glyv = gallery
w com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show external hard drives on desktop
w com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# ─── Keyboard ─────────────────────────────────────────────

echo "--- Keyboard"

# Fn key: Change Input Source (0=emoji, 1=do nothing, 2=input source, 3=dictation)
w com.apple.HIToolbox AppleFnUsageType -int 2

# Fast key repeat. Units of ~15ms. macOS defaults: InitialKeyRepeat=68, KeyRepeat=6
# InitialKeyRepeat=15 ≈ 0.225s delay before repeat kicks in
# KeyRepeat=2 ≈ 0.03s interval between repeats
# Requires logout/restart to take effect.
w NSGlobalDomain InitialKeyRepeat -int 15
w NSGlobalDomain KeyRepeat -int 2

# ─── Hot Corners ──────────────────────────────────────────
# All hot corners disabled (macOS default).

# ─── Locale ───────────────────────────────────────────────
# English UI with German region formats (dates, currency, etc.)
# Set via System Settings > General > Language & Region; not settable
# via defaults write alone. Documented for reference:
#   AppleLocale = "en_US@rg=dezzzz"
#   AppleLanguages = ("en-US", "de-DE")

# ─── Keyboard Layout ─────────────────────────────────────
# ABC keyboard layout. Set via System Settings > Keyboard > Input Sources.
# Documented for reference:
#   KeyboardLayout Name = ABC
#   KeyboardLayout ID = 252

# ─── Restart affected services ────────────────────────────

if ! $DRY_RUN; then
  echo ""
  echo "==> Restarting affected services…"
  killall Dock    2>/dev/null || true
  killall Finder  2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  echo "==> Done. Some changes may require logout/restart."
else
  echo ""
  echo "==> Dry run complete. Run without --dry-run to apply."
fi
