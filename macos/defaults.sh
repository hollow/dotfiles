#!/usr/bin/env zsh
#
# macOS defaults — non-default settings
#
# Apply:         ./macos/defaults.sh
# Review:        ./macos/defaults.sh --dry-run
# List tracked:  ./macos/defaults.sh --list-tracked  (used by reconcile.sh)
#
# Some changes require a logout/restart to take full effect.
# Affected services (Dock, Finder, etc.) are restarted at the end.
#

DRY_RUN=false
LIST_TRACKED=false
case "${1:-}" in
  --dry-run)      DRY_RUN=true ;;
  --list-tracked) LIST_TRACKED=true ;;
esac

typeset -i _dry_ok=0 _dry_change=0

# In dry-run/list-tracked, section headers are suppressed
section() { $DRY_RUN || $LIST_TRACKED || echo "--- $*"; }

w() {
  local domain="$1" key="$2" type="$3" val="$4"

  if $LIST_TRACKED; then
    # Emit TSV for reconcile.sh to auto-build its TRACKED map
    [[ "$type" == -array* || "$type" == -dict* ]] && return
    local normalized
    case "$type" in
      -bool)   [[ "$val" == "true"  ]] && normalized="1" || normalized="0" ;;
      -int|-float|-string) normalized="$val" ;;
      *) normalized="$type" ;;  # no type flag: w domain key value
    esac
    printf "%s\t%s\t%s\n" "$domain" "$key" "$normalized"
    return
  fi

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

if ! $LIST_TRACKED; then
  echo "==> Applying macOS defaults…"
  if $DRY_RUN; then
    echo ""
    printf "  %-8s  %-26s  %-38s  %s\n" "STATUS" "DOMAIN" "KEY" "VALUE"
    printf "  %-8s  %-26s  %-38s  %s\n" "--------" "--------------------------" "--------------------------------------" "-----"
  fi
  echo ""
fi

# ─── Appearance ───────────────────────────────────────────

section "Appearance"

# Dark mode
w NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Menu bar: auto-hide (0 = always, 1 = desktop only, 2 = fullscreen only, 3 = never).
# `defaults write` here is unreliable — ControlCenter writes back its in-memory value on
# restart. Change via System Settings > Control Center > Automatically hide menu bar.
w com.apple.controlcenter AutoHideMenuBarOption -int 2

# Hide menu bar in fullscreen (paired with AutoHideMenuBarOption=2 above)
w NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

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

# Enable App Exposé trackpad gesture (three-finger swipe down)
w com.apple.dock showAppExposeGestureEnabled -bool true

# Enable Mission Control trackpad gesture (three-finger swipe up)
w com.apple.dock showMissionControlGestureEnabled -bool true

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

# Disable warning when changing a file's extension
w com.apple.finder FXEnableExtensionChangeWarning -bool false

# Default to list view in all windows
# Nlsv = list, icnv = icon, clmv = column, glyv = gallery
w com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Hide external hard drives on desktop
w com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Hide removable media (CDs, DVDs, iPods) on desktop
w com.apple.finder ShowRemovableMediaOnDesktop -bool false

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

# Use F1, F2, etc. keys as standard function keys (hold fn for special features)
w NSGlobalDomain com.apple.keyboard.fnState -bool true

# Keyboard shortcuts (system-wide)
# Edit macos/symbolichotkeys.plist or re-export after changing in System Settings:
#   defaults export com.apple.symbolichotkeys macos/symbolichotkeys.plist
if ! $LIST_TRACKED; then
  DIR="$(cd "$(dirname "$0")" && pwd)"
  if $DRY_RUN; then
    if ! diff -q <(defaults export com.apple.symbolichotkeys - | plutil -convert xml1 - -o -) "$DIR/symbolichotkeys.plist" &>/dev/null; then
      printf "  %-8s  %-26s  %-38s  %s\n" "change" "com.apple.symbolichotkeys" "(plist)" "differs from stored"
      (( _dry_change++ ))
    else
      (( _dry_ok++ ))
    fi
  else
    defaults import com.apple.symbolichotkeys "$DIR/symbolichotkeys.plist"
  fi
fi

# Fast key repeat. Units of ~15ms. macOS defaults: InitialKeyRepeat=68, KeyRepeat=6
# InitialKeyRepeat=15 ≈ 0.225s delay before repeat kicks in
# KeyRepeat=2 ≈ 0.03s interval between repeats
# Requires logout/restart to take effect.
w NSGlobalDomain InitialKeyRepeat -int 15
w NSGlobalDomain KeyRepeat -int 2

# Disable swipe-to-navigate (two-finger swipe between pages in browsers, etc.)
w NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

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

# ─── Third-party apps ─────────────────────────────────────
# To track a new app: find its domain via `defaults domains | tr ',' '\n' | grep -i <name>`,
# then add `w <domain> <key> ...` lines below AND the domain to DOMAINS in reconcile.sh.

# CleanMyMac: maintenance / malware scanner
# Enable menu bar app
w com.macpaw.CleanMyMac-setapp MenuAppEnabled -bool true
# Show assistant recommendations in the UI
w com.macpaw.CleanMyMac-setapp ShowAssistantRecommendations -bool true
# Settings in the Setapp group container plist (not a regular defaults domain,
# so addressed by full path).
CMM_PLIST="$HOME/Library/Group Containers/S8EX82NJP6.com.macpaw.CleanMyMac-setapp/Library/Preferences/S8EX82NJP6.com.macpaw.CleanMyMac-setapp.plist"
# Disable Smart Care reminder nags
w "$CMM_PLIST" SmartCareReminderEnabled -bool false
# Disable custom themes (use system appearance)
w "$CMM_PLIST" CustomThemes -bool false
# Silence sound effects
w "$CMM_PLIST" SoundsEnabled -bool false
# Disable trash-size alerts
w "$CMM_PLIST" TrashSizeAlertsEnabled -bool false
# Malware scan mode: "protected" (continuous) vs "manual"
w "$CMM_PLIST" MalwareScanMode -string "protected"

# ForkLift: file manager / SFTP client
w com.binarynights.forklift-setapp theme -string "DefaultDark"
# Terminal app for "Open in Terminal". 5 = Ghostty (mapping inferred)
w com.binarynights.forklift-setapp TerminalApplication -int 5
# Hide title bar (show toolbar only)
w com.binarynights.forklift-setapp hideTitleBar -bool true
# Show path bar
w com.binarynights.forklift-setapp hidePathBar -bool false
# Hide device info in sidebar
w com.binarynights.forklift-setapp showDeviceInfo -bool false
# Info pane mode: 0 = off
w com.binarynights.forklift-setapp infoMode -int 0

# Raycast: launcher (replaces Spotlight; Spotlight hotkey disabled in symbolichotkeys.plist)
# Global hotkey format: "<Modifier>-<keycode>". 49 = spacebar, so Command-49 = ⌘Space.
w com.raycast.macos raycastGlobalHotkey -string "Command-49"
# Hide menu bar icon
w com.raycast.macos "NSStatusItem VisibleCC raycastIcon" -bool false
# Esc key behavior: 1 = close window (vs minimize)
w com.raycast.macos raycastWindowEscapeKeyBehavior -int 1

# ─── Restart affected services ────────────────────────────

if ! $LIST_TRACKED; then
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
fi
