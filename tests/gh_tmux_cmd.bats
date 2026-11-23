#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/tmux" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TMUX_CALL_LOG"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/tmux"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export TMUX_CALL_LOG="$BATS_TEST_TMPDIR/tmux.log"
}

@test "opens a titled, non-waiting floating pane with intact arguments" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'PR #12' gh pr view 12 --repo 'owner/repo'
  [ "$status" -eq 0 ]
  [ "$(head -1 "$TMUX_CALL_LOG")" = new-pane ]
  grep -qx -- '-x' "$TMUX_CALL_LOG"
  grep -qx -- '80%' "$TMUX_CALL_LOG"
  grep -qx -- '-y' "$TMUX_CALL_LOG"
  grep -qx -- '70%' "$TMUX_CALL_LOG"
  grep -qx -- '-k' "$TMUX_CALL_LOG"
  grep -qx -- '-T' "$TMUX_CALL_LOG"
  grep -qx -- ' PR 12 ' "$TMUX_CALL_LOG"
  grep -qx -- 'owner/repo' "$TMUX_CALL_LOG"
  ! grep -qx -- '-W' "$TMUX_CALL_LOG"
}

@test "missing command fails before contacting tmux" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'Missing'
  [ "$status" -ne 0 ]
  [ ! -e "$TMUX_CALL_LOG" ]
}
