---
name: macos-defaults
description: Help discover macOS plist keys and add/update entries in macos/defaults.sh. Use when the user wants to track a new macOS setting or remove an existing one.
---

The user wants to add, change, or remove a macOS default in this dotfiles repo.

## Workflow

1. **Discover the key** — If the user describes a setting rather than giving the exact key, run:
   ```
   defaults read <domain> 2>/dev/null | grep -i <keyword>
   ```
   Use `./macos/reconcile.sh --domains` to see which domains are scanned. Common domains: `NSGlobalDomain`, `com.apple.dock`, `com.apple.finder`, `com.apple.WindowManager`, `com.apple.Accessibility`, `com.apple.HIToolbox`.

2. **Check the current value** — Run `defaults read <domain> <key>` to see what's set now.

3. **Update `macos/defaults.sh`** — Add the `w` call in the correct section:
   ```
   w <domain> <key> -bool true|false
   w <domain> <key> -int <n>
   w <domain> <key> -string "<value>"
   ```
   Add a brief comment above the line explaining what the setting does and any non-obvious values (e.g., enum meanings).

   `reconcile.sh` auto-generates its `TRACKED` map from `defaults.sh --list-tracked` — no manual sync needed.

4. **Consider noise** — If the key emits ephemeral side-effects that show up in `reconcile.sh` output, add a pattern to `NOISE_PATTERNS` in `reconcile.sh`. Use a minimal regex that matches only the noisy key(s).

5. **Verify** — Run `./macos/defaults.sh --dry-run` and confirm the new entry appears as "set" or shows the correct expected value. Run `./macos/reconcile.sh` to confirm no unexpected drift.

6. **Apply** — Tell the user to run `./macos/defaults.sh` to apply, then `./macos/reconcile.sh --snapshot` if they want to update the baseline.

## Notes

- Do not add `w` calls for keys managed via `symbolichotkeys.plist` — the plist diff is handled separately.
- For array/dict types, `--dry-run` always reports them as "set" (can't compare scalars); this is expected.
- Some changes (key repeat, etc.) require logout/restart — note this in the comment.
