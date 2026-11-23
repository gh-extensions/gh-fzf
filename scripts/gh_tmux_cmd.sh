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

    display-view  Open a non-modal floating pane (requires tmux 3.8), leaving
                  the caller free to use the finder. Exited panes stay open
                  until explicitly closed with tmux kill-pane (prefix x).

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

# Open a titled, non-modal floating pane. Do not use -W: waiting here would
# block fzf until the command exits. -m prevents short commands from vanishing
# before we can set remain-on-exit on this pane and explains how to close them.
# Unlike -m alone, remain-on-exit on doesn't destroy the pane when the user
# presses the tmux prefix to switch
# sessions. The user can explicitly close it with prefix x.
_tmux_display_view() {
  local title pane_id
  title=$(_tmux_strip_name "$1")
  shift

  # Center an 80% × 70% pane; without -X/-Y tmux cascades from the top-left.
  pane_id=$(tmux new-pane -P -F '#{pane_id}' -x '80%' -y '70%' -X '10%' -Y '15%' \
    -m 'View exited — close with tmux prefix + x' -T " $title " "$@")
  tmux set-option -p -t "$pane_id" remain-on-exit on
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
