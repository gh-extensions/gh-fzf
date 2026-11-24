#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/tmux" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TMUX_CALL_LOG.$1"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/tmux"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export TMUX_CALL_LOG="$BATS_TEST_TMPDIR/tmux.log"
}

@test "opens a titled floating pane running tmux-view with intact arguments" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'PR #12' gh pr view 12 --repo 'owner/repo'
  [ "$status" -eq 0 ]
  [ "$(head -1 "$TMUX_CALL_LOG.new-pane")" = new-pane ]
  grep -qx -- '-x' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '80%' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-y' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '70%' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-X' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '10%' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-Y' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '15%' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-c' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- "$PWD" "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-e' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'GH_PAGER=cat' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'GH_FORCE_TTY=1' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '-T' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'PR 12' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '--' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'tmux-view' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'gh' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'pr' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'view' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '12' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- '--repo' "$TMUX_CALL_LOG.new-pane"
  grep -qx -- 'owner/repo' "$TMUX_CALL_LOG.new-pane"
  ! grep -qx -- '-W' "$TMUX_CALL_LOG.new-pane"
}

@test "enables floating-pane border titles when border status is off" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'PR #12' gh pr view 12
  [ "$status" -eq 0 ]
  [ "$(head -1 "$TMUX_CALL_LOG.set-option")" = set-option ]
  grep -qx -- 'pane-border-status' "$TMUX_CALL_LOG.set-option"
  grep -qx -- 'top-floating' "$TMUX_CALL_LOG.set-option"
  ! grep -qx -- 'pane-border-format' "$TMUX_CALL_LOG.set-option"
}

@test "leaves an existing border status setting alone" {
  cat > "$BATS_TEST_TMPDIR/bin/tmux" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == show-options ]]; then
  printf 'bottom\n'
  exit 0
fi
printf '%s\n' "$@" > "$TMUX_CALL_LOG.$1"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/tmux"

  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'PR #12' gh pr view 12
  [ "$status" -eq 0 ]
  [ ! -e "$TMUX_CALL_LOG.set-option" ]
}

@test "missing command fails before contacting tmux" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-view 'Missing'
  [ "$status" -ne 0 ]
  [ ! -e "$TMUX_CALL_LOG.new-pane" ]
  [ ! -e "$TMUX_CALL_LOG.set-option" ]
}

@test "display-watch subcommand is gone" {
  run "$REPO_ROOT/scripts/gh_tmux_cmd.sh" display-watch 'Run 42' gh run watch 42
  [ "$status" -ne 0 ]
  [ ! -e "$TMUX_CALL_LOG.new-pane" ]
}
