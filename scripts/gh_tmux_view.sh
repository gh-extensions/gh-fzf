#!/usr/bin/env bash
set -euo pipefail

# Run inside a tmux floating pane. The foreground pager/watch reader keeps the
# pane alive across session switches; q closes it without a global tmux binding.
mode=${1:?view or watch required}
shift
[[ $# -gt 0 ]] || { printf 'command required\n' >&2; exit 1; }

case "$mode" in
view)
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  # gh normally selects its own pager based on the terminal. Capture a complete
  # document, including errors, and always show it in a pager that waits for q.
  if GH_PAGER=cat GH_FORCE_TTY=1 "$@" >"$tmp" 2>&1; then
    :
  else
    printf '\nCommand failed. Press q to close.\n' >>"$tmp"
  fi
  LESS=-R less -- "$tmp"
  ;;
watch)
  # gh pr checks --watch and gh run watch use Ctrl-C, not q. They do not read
  # stdin; give stdin to this wrapper so q can stop the child process.
  "$@" </dev/null &
  pid=$!
  trap 'kill "$pid" 2>/dev/null || true' EXIT
  printf 'Press q to stop watching.\n'
  stopped=false
  while kill -0 "$pid" 2>/dev/null; do
    key=''
    if IFS= read -rsn1 -t 0.2 key </dev/tty && [[ "$key" == q ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      stopped=true
      break
    fi
  done
  if wait "$pid"; then
    status=0
  else
    status=$?
  fi
  pid=''
  if [[ "$stopped" != true ]]; then
    printf '\nWatch finished (exit %s). Press q to close.\n' "$status"
    while true; do
      key=''
      IFS= read -rsn1 key </dev/tty || break
      [[ "$key" == q ]] && break
    done
  fi
  ;;
*)
  printf 'Unknown view mode: %s\n' "$mode" >&2
  exit 1
  ;;
esac
