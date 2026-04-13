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

typeset -i _dry_ok=0 _dry_change=0

# In dry-run, section headers are suppressed (table has no sub-headers)
section() { $DRY_RUN || echo "--- $*"; }

w() {
  local domain="$1" key="$2" type="$3" val="$4"

  if $DRY_RUN; then
    # Arrays/dicts can't be compared as scalars — always report as change
    if [[ "$type" == -array* || "$type" == -dict* ]]; then
      printf "  %-8s  %-26s  %-38s  %s\n" "set" "$domain" "$key" "(array)"
      (( _dry_change++ ))
      return
    fi

    # Normalize desired value to what `defaults read` would return
    local desired
    case "$type" in
      -bool)   [[ "$val" == "true"  ]] && desired="1" || desired="0" ;;
      -int)    desired="$val" ;;
      -float)  desired="$val" ;;
      -string) desired="$val" ;;
      *)       desired="$type" ;;  # no type flag: w domain key value
    esac

    local current
    current=$(defaults read "$domain" "$key" 2>/dev/null)

    if [[ -z "$current" ]]; then
      printf "  %-8s  %-26s  %-38s  %s\n" "set" "$domain" "$key" "→ $desired"
      (( _dry_change++ ))
    elif [[ "$current" != "$desired" ]]; then
      printf "  %-8s  %-26s  %-38s  %s\n" "change" "$domain" "$key" "$current → $desired"
      (( _dry_change++ ))
    else
      (( _dry_ok++ ))
    fi
  else
    defaults write "$@"
  fi
}

echo "==> Applying macOS defaults…"
if $DRY_RUN; then
  echo ""
  printf "  %-8s  %-26s  %-38s  %s\n" "STATUS" "DOMAIN" "KEY" "VALUE"
  printf "  %-8s  %-26s  %-38s  %s\n" "--------" "--------------------------" "--------------------------------------" "-----"
fi
echo ""

# ─── Appearance ───────────────────────────────────────────

section "Appearance"

# Dark mode
w NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Menu bar: auto-hide (0 = always, 1 = desktop only, 2 = fullscreen only, 3 = never)
w com.apple.controlcenter AutoHideMenuBarOption -int 3

# Show menu bar in fullscreen
w NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true

# Disable transparency (windows, menu bar)
w com.apple.Accessibility reduceTransparency -bool true

# Double-click title bar: Fill (instead of minimize)
w NSGlobalDomain AppleActionOnDoubleClick -string "Fill"

# ─── Dock ─────────────────────────────────────────────────

section "Dock"

# Auto-hide the Dock
w com.apple.dock autohide -bool true

# Don't show recent applications in Dock
w com.apple.dock show-recents -bool false

# ─── Window Manager ──────────────────────────────────────

section "Window Manager"

# No gaps between tiled windows
w com.apple.WindowManager EnableTiledWindowMargins -bool false

# Click desktop to show desktop: only in Stage Manager (hide in standard)
w com.apple.WindowManager HideDesktop -bool true

# Show desktop icons
w com.apple.WindowManager StandardHideDesktopIcons -bool false

# Hide widgets on desktop
w com.apple.WindowManager StandardHideWidgets -bool true
w com.apple.WindowManager StageManagerHideWidgets -bool true

# Disable window tiling by dragging to screen edges
w com.apple.WindowManager EnableTilingByEdgeDrag -bool false
w com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

# Restore windows when reopening apps
w NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true

# ─── Finder ───────────────────────────────────────────────

section "Finder"

# Show all file extensions in Finder
w NSGlobalDomain AppleShowAllExtensions -bool true

# Default to list view in all windows
# Nlsv = list, icnv = icon, clmv = column, glyv = gallery
w com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show external hard drives on desktop
w com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# Show path bar and status bar
w com.apple.finder ShowPathbar -bool true
w com.apple.finder ShowStatusBar -bool true

# New windows open to home folder (PfHm)
w com.apple.finder NewWindowTarget -string "PfHm"

# Sort folders before files
w com.apple.finder _FXSortFoldersFirst -bool true

# Auto-remove items from Trash after 30 days
w com.apple.finder FXRemoveOldTrashItems -bool true

# ─── Keyboard ─────────────────────────────────────────────

section "Keyboard"

# Fn key: Show Emoji & Symbols (0=nothing, 1=input source, 2=emoji, 3=dictation)
w com.apple.HIToolbox AppleFnUsageType -int 2

# Fast key repeat. Units of ~15ms. macOS defaults: InitialKeyRepeat=68, KeyRepeat=6
# InitialKeyRepeat=15 ≈ 0.225s delay before repeat kicks in
# KeyRepeat=2 ≈ 0.03s interval between repeats
# Requires logout/restart to take effect.
w NSGlobalDomain InitialKeyRepeat -int 15
w NSGlobalDomain KeyRepeat -int 2

# ─── Typing & Text ────────────────────────────────────────

section "Typing & Text"

# Disable press-and-hold accent popup (enables key repeat for accented keys)
# Default: 1 (popup). Set to 0 so holding a key repeats the character.
w NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable auto-capitalization
w NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable auto-correct (spelling)
w NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-correct in web views
w NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false

# Disable inline predictive text completions
w NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false

# Disable continuous spell checking
w NSGlobalDomain NSAllowContinuousSpellChecking -bool false

# ─── Apps ─────────────────────────────────────────────────

section "Apps"

# TextEdit: use plain text by default
w com.apple.TextEdit RichText -bool false

# Disk Utility: show all devices in sidebar
w com.apple.DiskUtility SidebarShowAllDevices -bool true

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
  echo "==> $_dry_change would change, $_dry_ok already correct."
  echo "    Run without --dry-run to apply."
fi
