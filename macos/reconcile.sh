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
  # Third-party apps
  com.eltima.elmedia-setapp
  com.raycast.macos
  com.binarynights.forklift-setapp
  com.macpaw.CleanMyMac-setapp
)

# ── Keys to ignore (ephemeral / noise) ──────────────────

local -a NOISE_PATTERNS=(
  '(last|Last|LAST).*(stamp|Stamp|date|Date|time|Time|check|Check|interval|Interval|posted|Posted)'
  '(analytics|Analytics|telemetry|Telemetry|heartbeat|Heartbeat)'
  # CloudKit startup time (written on every launch by many apps)
  '^CKStartupTime$'
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
  'NewWindowTargetPath'
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
  # Mail runtime counters/state
  '^MailDockBadge$'
  '^kDefaultsKeyLastVerifiedMessageID$'
  '^MSAssetDownloadRetryInterval\.'
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
  # Safari UI/session state
  '\.UpdateDate$'
  '^DateOfLastSessionStateDataCleanup$'
  '^LastExtensionSelectedInPreferences$'
  '^NSPreferencesSelectedIndex$'
  # Setapp internal state (third-party apps distributed via Setapp)
  '^SS_'
  '^STP_'
  'com_apple_SwiftUI_Settings_selectedTabIndex'
  # Raycast: onboarding flags, AI/extension/calculator runtime state, UI restore data,
  # internal migration markers, install-time defaults, granted folder permissions, install IDs
  '^onboarding'
  '^raycastAI_'
  '^calculator_'
  '^commandsPreferencesExpandedItemIds$'
  '^emojiPicker_skinTone$'
  '^fallbackSearches_didMigrateScriptCommands$'
  '^raycast-preferences-restorableData$'
  '^raycastGlobalHotkeyMigrated$'
  '^aiDynamicPlaceholdersMigrationDate$'
  '^database_lastValid'
  '^floatingNotes_'
  '^hasQueuedStatusBarHint$'
  '^hasShownStatusBarHintAfterOnboarding$'
  '^mainWindow_isMonitoringGlobalHotkeys$'
  '^permissions\.'
  '^raycastAnonymousId$'
  '^raycastInstallationDate$'
  '^raycastLoginItemAutoInstalled$'
  '^raycastPreferredWindowMode$'
  '^raycastShouldFollowSystemAppearance$'
  '^raycast-updates-'
  '^showGettingStartedLink$'
  '^store_migrated'
  '^store_termsAccepted$'
  '^subscriptions_active$'
  '^useHyperKeyIcon$'
  '^command-extension_'
  # ForkLift: ephemeral UI/session state
  '^previewDividerPosition$'
  '^settingsSelection$'
  '^connectViewProtocol$'
  '^latestCrashReport$'
  '^GetInfoWindowFrame$'
  '^DatabaseModified$'
  '^KeyWindow(Left|Right)ViewMode$'
  # CleanMyMac: one-time migration flags, telemetry eligibility, version tracking
  '^CMIsUserEligibleForAppsStatistics$'
  '^FRServiceLastKnownVersion$'
  '^KeychainAccessibilityMigration$'
  # CleanMyMac: DB hash/size, launch/clean counters, instance/bundle state
  '^DbHash$'
  '^DbSize$'
  '^LaunchCount$'
  '^TotalCleansCount$'
  '^CMAUIdentifier$'
  '^LastActiveBundle$'
)

# Build single alternation regex for O(1) noise checks
NOISE_RE="${(j:|:)NOISE_PATTERNS}"
is_noise() { [[ "$1" =~ $NOISE_RE ]]; }

# ── Tracked settings — auto-generated from defaults.sh ──
# defaults.sh is the single source of truth; no manual sync needed.

typeset -A TRACKED
while IFS=$'\t' read -r _d _k _v; do
  TRACKED[${_d}${TAB}${_k}]="$_v"
done < <("$SCRIPT_DIR/defaults.sh" --list-tracked)

# ── Dump current state as sorted TSV: domain\tkey\tvalue ─

dump_current() {
  local domain raw line key val
  for domain in "${DOMAINS[@]}"; do
    raw=$(defaults read "$domain" 2>/dev/null) || continue
    while IFS= read -r line; do
      # Match top-level keys: exactly 4 leading spaces, key = value;
      # [^"= ] ensures first char of key is not a space, preventing nested entries
      # (nested entries have 8+ leading spaces; the extra spaces would land in key)
      [[ "$line" =~ '^    "?([^"= ][^"=]*)"? = (.+);$' ]] || continue
      key="${match[1]## }"; key="${key%% }"
      val="${match[2]## }"; val="${val%% }"
      # Skip nested structures and binary/data blobs
      [[ "$val" == "(" || "$val" == "{" ]] && continue
      [[ "$val" == *"length ="*"bytes ="* ]] && continue
      print "${domain}${TAB}${key}${TAB}${val}"
    done <<< "$raw"
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

# Build key set for O(1) removed-key lookup (avoids O(n*m) grep in diff loop)
typeset -A CURRENT_KEYS
while IFS=$'\t' read -r _d _k _v; do
  CURRENT_KEYS[${_d}${TAB}${_k}]=1
done < "$CURRENT"

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

while IFS= read -r line; do
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
    (( ${+CURRENT_KEYS[${domain}${TAB}${key}]} )) || removed_lines+=("$domain → $key (was: $val)")
  fi
done <<< "$diffout"

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
