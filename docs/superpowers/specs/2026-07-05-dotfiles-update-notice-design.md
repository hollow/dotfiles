# Dotfiles update notice design

## Goal

Make the shell-only dotfiles update notice more visually distinct without changing update-check behavior.

## Current context

- The notice is emitted by `zsh/dotfiles-update-check` when cached state is `behind`.
- The current output is plain text: `dotfiles update available; run zup`.
- The checker is zsh-only and runs during shell startup through `.zshrc`.
- Existing tests assert the notice path and the no-noise behavior for non-actionable states.

## User decision

Use a noticeable style: colored icon plus highlighted `zup`, visible without looking like an error.

## Design

Use zsh prompt expansion with `print -P`, not raw ANSI escapes or a new style abstraction.

The `behind` notice should render as:

```text
󰚰 dotfiles update available — run zup
```

with:

- `󰚰` in cyan;
- normal terminal foreground for `dotfiles update available — run`;
- `zup` in green;
- prompt colors reset after each colored segment.

Implementation line:

```zsh
print -P -- "%F{cyan}󰚰%f dotfiles update available — run %F{green}zup%f"
```

## Non-goals

- No behavior change to update detection.
- No new helper abstraction for one notice line.
- No raw ANSI escape strings.
- No macOS Notification Center output.
- No louder warning/error styling.

## Tests

Update the notice tests so they still verify:

- `behind` prints a notice;
- non-actionable states print nothing;
- missing or malformed state stays silent;
- the user-facing notice includes the Nerd Font icon, the update text, and `zup`.

Avoid brittle assertions on terminal-specific color byte sequences unless the test captures zsh `print -P` output deterministically in this repo's test shell.
