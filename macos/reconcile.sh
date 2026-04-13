#!/usr/bin/env zsh
#
# macOS defaults reconciliation — full scan
#
# Compares ALL current macOS settings in user-facing domains against
# a stored baseline snapshot. Reports drift from tracked settings and
# discovers any new changes since the last snapshot.
#
# Usage:
#   ./macos/reconcile.sh              — compare current vs baseline
#   ./macos/reconcile.sh --snapshot   — save current state as new baseline
#   ./macos/reconcile.sh --domains    — list all scanned domains
#

setopt PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/macos-defaults"
BASELINE="$STATE_DIR/baseline.tsv"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
TAB=$'\t'

# ── Domains to scan ──────────────────────────────────────

local -a DOMAINS=(
  NSGlobalDomain
  com.apple.dock
  com.apple.finder
  com.apple.WindowManager
  com.apple.Accessibility
  com.apple.AppleMultitouchTrackpad
  com.apple.AppleMultitouchMouse
  com.apple.driver.AppleBluetoothMultitouch.trackpad
  com.apple.driver.AppleBluetoothMultitouch.mouse
  com.apple.HIToolbox
  com.apple.screencapture
  com.apple.screensaver
  com.apple.controlcenter
  com.apple.loginwindow
  com.apple.Safari
  com.apple.mail
  com.apple.Terminal
  com.apple.TextEdit
  com.apple.ActivityMonitor
  com.apple.DiskUtility
  com.apple.SoftwareUpdate
  com.apple.Bluetooth
  com.apple.universalaccess
  com.apple.keyboard
  com.apple.menuextra.clock
  com.apple.menuextra.battery
  com.apple.LaunchServices
  com.apple.CrashReporter
  com.apple.print.PrintingPrefs
  com.apple.desktopservices
  com.apple.frameworks.diskimages
  com.apple.NetworkBrowser
  com.apple.TimeMachine
)

# ── Keys to ignore (ephemeral / noise) ──────────────────

local -a NOISE_PATTERNS=(
  '(last|Last|LAST).*(stamp|Stamp|date|Date|time|Time|check|Check|interval|Interval|posted|Posted)'
  '(analytics|Analytics|telemetry|Telemetry|heartbeat|Heartbeat)'
  'mod-count'
  'recent-apps'
  'RecentDocuments'
  'RecentSearches'
  'NSNavPanel'
  'NSWindow Frame'
  'NSStatusItem'
  'NSToolbar'
  'NSSplitView'
  'NSTableView'
  'FXRecentFolders'
  'FXDesktopVolumePositions'
  'GoToField'
  'SearchCriteria'
  'BackupAlias'
  'bootUUID'
  'urgentSubmission'
  'FK_SidebarWidth'
  'TrashState'
  'SpacesDisplayConfiguration'
  'ControlCenterDisplayable'
  'LiveActivityState'
  'NSLinguisticDataAssets'
  'NSSpellChecker'
  'AKLast'
  'ACDMonthly'
  'DataSeparatedDisplayNameCache'
  'DownloadsFolderListViewSettingsVersion'
  'ProfileCurrentVersion'
  'HasMigrated'
  'HasAttempted'
  'HasDisplayed'
  'oneTimeSS'
  'MiniBuddy'
  'GuestPassDeviceUUID'
  'CommandHistory'
  'shouldShowRSVP'
  'tokenRemovalAction'
  'SecureKeyboardEntry'
  'TALLogoutReason'
  'lastNowPlayed'
  'persistent-apps'
  'persistent-others'
  'Window Settings'
  'AppleLanguagesSchemaVersion'
  'NSUserDictionaryReplacementItems'
  'NSUserQuotesArray'
  'KB_DoubleQuoteOption'
  'KB_SingleQuoteOption'
  'KB_SpellingLanguage'
  'AppleInputSourceHistory'
  'AppleSelectedInputSources'
  'AppleEnabledInputSources'
  'AppleCurrentKeyboardLayoutInputSourceID'
  'com\.apple\.finder\.SyncExtensions'
  'trash-full'
  '^raw='
  'History'
  'MouseKeys'
  'closeView'
  'liveSpeech'
  'slowKey'
  'stickyKey'
  'sessionChange'
  'useStickyKeys'
  # Safari runtime/migration/config state
  'ExtensionsEnabled'
  'HideStartPage'
  'HomePage'
  'LocalFileRestrictions'
  'PrivateBrowsingRequires'
  'ShowSidebarInTopSites'
  # SoftwareUpdate notification state
  'AvailableUpdatesNotification'
  'DDMUpdateNotification'
  'UserNotificationDate'
  'AutoUpdateMajorOSVersion'
  # universalaccess UI state (side-effects of enabling reduceTransparency)
  'AssistiveControlType'
  'customFonts'
  'dwellEnabled'
  'grayscale'
  'hoverTextEnabled'
  'hudNotified'
  'switchOnOffKey'
  'virtualKeyboardOnOff'
  'voiceOverOnOffKey'
  # Finder window/sidebar state
  'FXConnectTo'
  'FXICloudDrive'
  'FXLastSearchScope'
  'FXPreferencesWindow'
  'FXPreferredSearchViewStyle'
  'FXSidebarUpgraded'
  'FXDetached'
  'CopyProgressWindowLocation'
  'EmptyTrashProgressWindowLocation'
  'MountProgressWindowLocation'
  'PreferencesWindow\.'
  'PreviewPane'
  'SearchRecentsSavedViewStyle'
  'Sidebar.*SectionDisclosedState'
  'SidebarShowing'
  'SidebarWidth'
  'FontSizeCategory'
  # NSGlobalDomain UI/input noise
  '_HIHideMenuBar'
  'AppleKeyboardUIMode'
  'com\.apple\.keyboard\.fnState'
  'com\.apple\.mouse\.scaling'
  'com\.apple\.sound\.uiaudio'
  'NavPanelFileListMode'
  'NSPersonNameDefaultDisplayNameOrder'
  'NSPreferredSpellServerLanguage'
  # Terminal/TextEdit session state
  'TTAppPreferences'
  'DefaultProfilesVersion'
  'NSNavLastUserSetHideExtensionButtonState'
  # loginwindow / screencapture session state
  'TALLogoutSavesState'
  'last-selection-display'
  # AppleDictation side-effect
  'AppleDictationAutoEnable'
  # Accessibility side-effects of reduceTransparency
  'AccessibilityEnabled'
  'ApplicationAccessibilityEnabled'
  'GenericAccessibilityClientEnabled'
  'EnhancedBackgroundContrastEnabled'
  # universalaccess duplicate reduceTransparency key
  'reduceTransparency'
  # ActivityMonitor view preferences
  'ShowCategory'
  # controlcenter / dock noise
  'RemoteLiveActivitiesEnabled'
  'launchanim'
  # Trackpad gesture settings (managed via System Settings)
  'HIDScrollZoomModifierMask'
  'TrackpadThreeFinger'
  'TrackpadFourFinger'
  'TrackpadFiveFinger'
  'TrackpadTwoFinger'
  'TrackpadCorner'
  'TrackpadHand'
  'TrackpadHorizScroll'
  'TrackpadMomentumScroll'
  'TrackpadPinch'
  'TrackpadRightClick'
  'TrackpadRotate'
  'TrackpadScroll'
  'TrackpadDrag'
  'ActuateDetents'
  'Clicking'
  'Dragging'
  'DragLock'
  'FirstClickThreshold'
  'SecondClickThreshold'
  'ForceSuppressed'
  'USBMouseStopsTrackpad'
  'UserPreferences'
  # mail/terminal one-off migration keys
  'MailUpgraderPrePersistenceVersion'
  'Shell'
  # Safari runtime/migration state
  'DidMigrate'
  'DidClear'
  'DidGrant'
  'DidUpdate'
  'WBS'
  'IIO_LaunchInfo'
  'NewestLaunched'
  'NewTabPageLastModified'
  'SuccessfulLaunch'
  'Autoplay.*Whitelist'
  'UserAgentQuirks'
  'SafariVersion'
  'LastOS.*Safari'
  'SkipLoading'
  'UniversalSearch.*Notification'
  'SearchProviderIdentifier.*Migrated'
  'SafariProfiles'
  'com\.apple\.WebPrivacy'
  'WebKitPreferences\.'
  'WebKitRespect'
)

is_noise() {
  local key="$1" pat
  for pat in "${NOISE_PATTERNS[@]}"; do
    [[ "$key" =~ $pat ]] && return 0
  done
  return 1
}

# ── Tracked settings (must match defaults.sh) ───────────

typeset -A TRACKED
TRACKED[NSGlobalDomain${TAB}AppleInterfaceStyle]="Dark"
TRACKED[NSGlobalDomain${TAB}AppleMenuBarVisibleInFullscreen]="1"
TRACKED[com.apple.controlcenter${TAB}AutoHideMenuBarOption]="3"
TRACKED[com.apple.Accessibility${TAB}reduceTransparency]="1"
TRACKED[NSGlobalDomain${TAB}AppleActionOnDoubleClick]="Fill"
TRACKED[com.apple.dock${TAB}autohide]="1"
TRACKED[com.apple.dock${TAB}show-recents]="0"
TRACKED[com.apple.WindowManager${TAB}EnableTiledWindowMargins]="0"
TRACKED[com.apple.WindowManager${TAB}EnableTilingByEdgeDrag]="0"
TRACKED[com.apple.WindowManager${TAB}EnableTopTilingByEdgeDrag]="0"
TRACKED[com.apple.WindowManager${TAB}HideDesktop]="1"
TRACKED[com.apple.WindowManager${TAB}StandardHideDesktopIcons]="0"
TRACKED[com.apple.WindowManager${TAB}StandardHideWidgets]="1"
TRACKED[com.apple.WindowManager${TAB}StageManagerHideWidgets]="1"
TRACKED[com.apple.finder${TAB}FXPreferredViewStyle]="Nlsv"
TRACKED[com.apple.finder${TAB}ShowExternalHardDrivesOnDesktop]="1"
TRACKED[com.apple.HIToolbox${TAB}AppleFnUsageType]="2"
TRACKED[NSGlobalDomain${TAB}InitialKeyRepeat]="15"
TRACKED[NSGlobalDomain${TAB}KeyRepeat]="2"
TRACKED[NSGlobalDomain${TAB}ApplePressAndHoldEnabled]="0"
TRACKED[NSGlobalDomain${TAB}NSAutomaticCapitalizationEnabled]="0"
TRACKED[NSGlobalDomain${TAB}NSAutomaticSpellingCorrectionEnabled]="0"
TRACKED[NSGlobalDomain${TAB}WebAutomaticSpellingCorrectionEnabled]="0"
TRACKED[NSGlobalDomain${TAB}NSAutomaticInlinePredictionEnabled]="0"
TRACKED[NSGlobalDomain${TAB}NSAllowContinuousSpellChecking]="0"
TRACKED[NSGlobalDomain${TAB}AppleShowAllExtensions]="1"
TRACKED[NSGlobalDomain${TAB}NSQuitAlwaysKeepsWindows]="1"
TRACKED[com.apple.finder${TAB}ShowPathbar]="1"
TRACKED[com.apple.finder${TAB}ShowStatusBar]="1"
TRACKED[com.apple.finder${TAB}NewWindowTarget]="PfHm"
TRACKED[com.apple.finder${TAB}_FXSortFoldersFirst]="1"
TRACKED[com.apple.finder${TAB}FXRemoveOldTrashItems]="1"
TRACKED[com.apple.TextEdit${TAB}RichText]="0"
TRACKED[com.apple.DiskUtility${TAB}SidebarShowAllDevices]="1"

# ── Dump current state as sorted TSV: domain\tkey\tvalue ─

dump_current() {
  local domain
  for domain in "${DOMAINS[@]}"; do
    local raw
    raw=$(defaults read "$domain" 2>/dev/null) || continue
    print -r -- "$raw" | while IFS= read -r line; do
      # Match top-level keys: exactly 4 leading spaces, key = value;
      # [^"= ] ensures first char of key is not a space, preventing nested entries
      # (nested entries have 8+ leading spaces; the extra spaces would land in key)
      if [[ "$line" =~ '^    "?([^"= ][^"=]*)"? = (.+);$' ]]; then
        local key="${match[1]}"
        local val="${match[2]}"
        key="${key## }"
        key="${key%% }"
        val="${val## }"
        val="${val%% }"
        # Skip nested structures
        [[ "$val" == "(" || "$val" == "{" ]] && continue
        # Skip binary/data blobs
        [[ "$val" == *"length ="*"bytes ="* ]] && continue
        print "${domain}${TAB}${key}${TAB}${val}"
      fi
    done
  done | sort
}

# ── Commands ─────────────────────────────────────────────

if [[ "${1:-}" == "--domains" ]]; then
  echo "Scanned domains (${#DOMAINS[@]}):"
  for d in "${DOMAINS[@]}"; do
    if defaults read "$d" &>/dev/null; then
      printf "  %-55s ✓\n" "$d"
    else
      printf "  %-55s —\n" "$d"
    fi
  done
  return 0
fi

if [[ "${1:-}" == "--snapshot" ]]; then
  echo "Saving baseline snapshot to $BASELINE …"
  dump_current > "$BASELINE"
  count=$(wc -l < "$BASELINE" | tr -d ' ')
  echo "Done. Captured $count settings across ${#DOMAINS[@]} domains."
  return 0
fi

# ── Reconcile ────────────────────────────────────────────

if [[ ! -f "$BASELINE" ]]; then
  echo "No baseline found. Creating initial snapshot…"
  dump_current > "$BASELINE"
  count=$(wc -l < "$BASELINE" | tr -d ' ')
  echo "Baseline saved with $count settings. Run again to detect changes."
  return 0
fi

CURRENT=$(mktemp)
trap 'rm -f "$CURRENT"' EXIT INT TERM
dump_current > "$CURRENT"

drift_lines=()
new_lines=()
removed_lines=()

# 1. Check tracked settings for drift

for tk in "${(@k)TRACKED}"; do
  expected="${TRACKED[$tk]}"
  domain="${tk%%${TAB}*}"
  key="${tk##*${TAB}}"
  current="$(defaults read "$domain" "$key" 2>/dev/null || print '<not set>')"
  if [[ "$current" != "$expected" ]]; then
    drift_lines+=("$domain → $key: expected='$expected' current='$current'")
  fi
done

# 2. Diff baseline vs current

diffout=$(diff "$BASELINE" "$CURRENT" 2>/dev/null) || true

print -r -- "$diffout" | while IFS= read -r line; do
  if [[ "$line" == "> "* ]]; then
    entry="${line#> }"
    domain="${entry%%${TAB}*}"
    rest="${entry#*${TAB}}"
    key="${rest%%${TAB}*}"
    val="${rest#*${TAB}}"

    is_noise "$key" && continue
    # Skip tracked settings
    (( ${+TRACKED[${domain}${TAB}${key}]} )) && continue

    new_lines+=("$domain → $key = $val")

  elif [[ "$line" == "< "* ]]; then
    entry="${line#< }"
    domain="${entry%%${TAB}*}"
    rest="${entry#*${TAB}}"
    key="${rest%%${TAB}*}"
    val="${rest#*${TAB}}"

    is_noise "$key" && continue

    # Only report if truly removed (not just changed value)
    if ! grep -qF "${domain}${TAB}${key}${TAB}" "$CURRENT" 2>/dev/null; then
      removed_lines+=("$domain → $key (was: $val)")
    fi
  fi
done

# ── Report ───────────────────────────────────────────────

if (( ${#drift_lines} == 0 && ${#new_lines} == 0 && ${#removed_lines} == 0 )); then
  echo "macOS defaults: all in sync, no new changes detected."
  return 0
fi

if (( ${#drift_lines} > 0 )); then
  echo "=== DRIFT: tracked settings changed from expected values ==="
  echo ""
  for d in "${drift_lines[@]}"; do echo "  - $d"; done
  echo ""
fi

if (( ${#new_lines} > 0 )); then
  echo "=== CHANGED/NEW: settings that differ from baseline snapshot ==="
  echo ""
  for n in "${new_lines[@]}"; do echo "  - $n"; done
  echo ""
fi

if (( ${#removed_lines} > 0 )); then
  echo "=== REMOVED: settings present in baseline but now gone ==="
  echo ""
  for r in "${removed_lines[@]}"; do echo "  - $r"; done
  echo ""
fi

echo "Review changes and update macos/defaults.sh if needed."
echo "Run './macos/reconcile.sh --snapshot' to update the baseline."
