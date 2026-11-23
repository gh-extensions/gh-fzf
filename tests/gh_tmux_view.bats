#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/less" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$LESS" > "$MOCK_LESS_OPTS"
cat "${@: -1}"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/less"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export MOCK_LESS_OPTS="$BATS_TEST_TMPDIR/less-opts"
}

@test "view captures successful output in a pager" {
  run "$REPO_ROOT/scripts/gh_tmux_view.sh" view bash -c 'printf "PR details\n"'
  [ "$status" -eq 0 ]
  [[ "$output" == *'PR details'* ]]
  [ "$(cat "$MOCK_LESS_OPTS")" = '-R' ]
}

@test "view keeps errors readable in the pager" {
  run "$REPO_ROOT/scripts/gh_tmux_view.sh" view bash -c 'printf "not found\n" >&2; exit 1'
  [ "$status" -eq 0 ]
  [[ "$output" == *'not found'* ]]
  [[ "$output" == *'Command failed. Press q to close.'* ]]
}

@test "watch: one q stops the running command and closes the pane" {
  command -v script >/dev/null && command -v timeout >/dev/null || skip 'requires script and timeout'
  run timeout 7 bash -c '{ sleep 1; printf q; } | script -q -e -c "$1 watch sleep 30" /dev/null' bash "$REPO_ROOT/scripts/gh_tmux_view.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Press q to stop watching.'* ]]
}

@test "watch: q closes the view after the command finishes" {
  command -v script >/dev/null && command -v timeout >/dev/null || skip 'requires script and timeout'
  run timeout 7 bash -c '{ sleep 1; printf q; } | script -q -e -c "$1 watch sleep 0.1" /dev/null' bash "$REPO_ROOT/scripts/gh_tmux_view.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Watch finished (exit 0). Press q to close.'* ]]
}
