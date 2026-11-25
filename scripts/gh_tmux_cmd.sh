#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

# Print usage to stdout
_show_help() {
  cat <<'EOF'
gh_tmux_cmd.sh - tmux helpers for gh-fzf

USAGE:
    gh_tmux_cmd.sh new-session   <name> [command...]
    gh_tmux_cmd.sh new-window    <name> [command...]
    gh_tmux_cmd.sh display-view  <title> <command...>

SUBCOMMANDS:
    new-session   Create a tmux session if it does not already exist, then
                  switch the client to it. '#' is stripped from the name.

    new-window    Open a new tmux window with the given name and command.
                  '#' is stripped from the name.

    display-view  Open a modal floating pane with the command output; Escape
                  or C-c close it, and once the command exits any key closes
                  it. The pane title is shown on the floating-pane border
                  (enabling top-floating border status when it is off).
                  Requires tmux 3.8.

ARGUMENTS:
    name          Session or window name. Any '#' characters are removed
                  and '.' characters are replaced with '_' before passing
                  to tmux (# is a tmux format string prefix).
    title         Floating pane title (same sanitization applied).
    command       Optional command to run inside the session, window, or pane.
EOF
}

# Strip '#' and replace '.' with '_' in a tmux session or window name.
# tmux treats '#' as a format string prefix, so it must be removed.
# '.' is replaced with '_' because tmux uses '.' as a target separator.
#
# Usage:  _tmux_strip_name <name>
# Input:  name  — raw session or window name
# Output: sanitized name printed to stdout
_tmux_strip_name() {
  printf '%s' "${1//#/}" | tr . _
}

# Create a named tmux session if it does not already exist, then switch the
# client to it. If no tmux client is attached (e.g. running non-interactively),
# the switch-client call is silently ignored.
#
# Usage:   _tmux_new_session <name> [command...]
# Args:
#   name     — session name (sanitized via _tmux_strip_name before use)
#   command  — optional command to run inside the new session
_tmux_new_session() {
  local name
  name=$(_tmux_strip_name "$1")
  shift
  local cmd=("$@")

  if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" "${cmd[@]+"${cmd[@]}"}"
  fi

  tmux switch-client -t "=$name" 2>/dev/null || true
}

# Open a new tmux window in the current session with the given name and
# optional command. Unlike new-session, a new window is always created even if
# one with the same name already exists.
#
# Usage:   _tmux_new_window <name> [command...]
# Args:
#   name     — window name (sanitized via _tmux_strip_name before use)
#   command  — optional command to run inside the new window
_tmux_new_window() {
  local name
  name=$(_tmux_strip_name "$1")
  shift
  local cmd=("$@")

  tmux new-window -n "$name" "${cmd[@]+"${cmd[@]}"}"
}

# Open a titled, modal floating pane. Escape or C-c close it via -D at any time;
# the trailing read holds the pane after the command exits, so any single key
# closes a finished view. Do not use -W: it would block fzf until that happens.
_tmux_display_view() {
  local title border_status
  title=$(_tmux_strip_name "$1")
  shift

  # Floating-pane titles are only drawn when border status lines are on. Use
  # the floating-only variant so tiled panes keep the user's choice; `top` and
  # `bottom` already cover floating panes, so leave those alone. Leave the
  # border *format* to the user: it is personal styling (and carries tmux's
  # clickable controls), so only the status toggle is ours to make.
  border_status=$(tmux show-options -wqv pane-border-status 2>/dev/null || true)
  if [[ -z "$border_status" || "$border_status" == off ]]; then
    tmux set-option -w pane-border-status top-floating
  fi

  # Center an 80% × 70% pane; without -X/-Y tmux cascades from the top-left.
  # -O -D: a modal pane, closed by Escape or C-c at any time. The trailing
  # read holds the pane after the command exits, so any single key closes the
  # view. No -W: it would block fzf until the view closes. GH_PAGER=cat keeps
  # closing one-step: on a real TTY gh would otherwise launch its own pager
  # and demand a second keypress. bash -c with "$@" passes the command through
  # without re-quoting, regardless of the user's default shell.
  tmux new-pane -O -D -x '80%' -y '70%' -X '10%' -Y '15%' -c "$PWD" \
    -e GH_PAGER=cat -T "$title" -- bash -c '"$@"; read -rsn1' _ "$@"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate function.
# ------------------------------------------------------------------------------
main() {
  local subcommand="${1:-}"

  case "$subcommand" in
  --help | -h | help)
    _show_help
    ;;
  new-session)
    shift
    [[ $# -ge 1 ]] || {
      gum log --level error 'new-session: name required'
      exit 1
    }
    _tmux_new_session "$@"
    ;;
  new-window)
    shift
    [[ $# -ge 1 ]] || {
      gum log --level error 'new-window: name required'
      exit 1
    }
    _tmux_new_window "$@"
    ;;
  display-view)
    shift
    [[ $# -ge 2 ]] || {
      gum log --level error 'display-view: title and command required'
      exit 1
    }
    _tmux_display_view "$@"
    ;;
  *)
    gum log --level error "unknown subcommand: ${subcommand:-(none)}"
    gum log --level warn 'Run gh_tmux_cmd.sh --help for usage.'
    exit 1
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
