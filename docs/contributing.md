# Contributing

## Getting started

1. Fork and clone the repository.
2. Make your changes in a feature branch.
3. Test manually by running the scripts directly:

```bash
# Run a command with debug output
DEBUG=1 ./gh-fzf issue

# Test a subcommand directly
DEBUG=1 ./scripts/gh_issue_cmd.sh add-label 42
DEBUG=1 ./scripts/gh_repo_cmd.sh clone owner/repo
```

4. Open a pull request against `main`.

## Project structure

```
gh-fzf                      # main entry point
scripts/
  gh_core.sh                # shared utilities (fzf options, repo detection)
  gh_issue.sh               # issue fzf view
  gh_issue_cmd.sh           # issue subcommands (list, add-label, help)
  gh_pr.sh                  # PR fzf view
  gh_pr_cmd.sh              # PR subcommands
  gh_repo.sh                # repo fzf view
  gh_repo_cmd.sh            # repo subcommands (list, clone, fork, help)
  gh_run.sh                 # run fzf view
  gh_run_cmd.sh             # run subcommands
  gh_search.sh              # search fzf views
  gh_search_cmd.sh          # search subcommands
templates/
  gh_issue_list.tmpl        # go template for issue list output
  gh_pr_list.tmpl           # go template for PR list output
  gh_repo_list.tmpl         # go template for repo list output
  gh_run_list.tmpl          # go template for run list output
  gh_search_*.tmpl          # go templates for search output
```

Each command follows the same pattern: a `gh_<cmd>.sh` file sets up the fzf
view and bindings, and a `gh_<cmd>_cmd.sh` file provides the subcommands
invoked by those bindings (and can be run directly for testing).

## Code conventions

- **Shell options**: Every script starts with `set -eo pipefail` for strict error handling.
- **Function naming**: Use `_gh_<cmd>_<action>` (e.g., `_gh_pr_list_cmd`, `_gh_repo_clone`). Leading underscore marks internal/sourced functions.
- **Docstring format**: Each function is preceded by a block comment with `# Name()`, `# DESCRIPTION:`, `# PARAMETERS:`, and `# RETURNS:` sections (see existing functions for the pattern).
- **Variable quoting**: Always quote variables. Use arrays (`local -a`) when a value needs word-splitting on whitespace — never rely on unquoted strings for argument expansion.
- **Debug support**: `[ -z "${DEBUG:-}" ] || set -x` at the top of each script enables trace output via `DEBUG=1`.

## Adding a new command

1. **Create the view file** `scripts/gh_<cmd>.sh`:
   - Source `gh_core.sh`.
   - Call `_gh_fzf_options "<CMD>"` to populate `$_fzf_options`.
   - Launch `fzf` with bindings that delegate to `gh_<cmd>_cmd.sh`.

2. **Create the subcommand file** `scripts/gh_<cmd>_cmd.sh`:
   - Source `gh_core.sh`.
   - Implement `_gh_<cmd>_list_cmd()` (and other actions).
   - Add a `main()` dispatcher and `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` guard so the file can be run directly.

3. **Wire into the main entry point** `gh-fzf`:
   - Source `scripts/gh_<cmd>.sh`.
   - Add a `<cmd>` case to the main `case` dispatcher that calls `_gh_<cmd>_list`.

4. **Add a template** `templates/gh_<cmd>_list.tmpl` for the `gh` JSON output if needed.

5. **Add docs** under `docs/<cmd>.md` describing the keyboard shortcuts and any flags.

## ShellCheck

Run ShellCheck before opening a PR:

```bash
shellcheck scripts/*.sh
```

Guidelines:
- **SC2086** (unquoted variable): Never disable this for string variables. For passthrough CLI arguments, use `_gh_parse_list_args` (nameref array, single-pass parser defined in `gh_core.sh`) and expand with `"${arr[@]}"`. SC2086 disables are only acceptable when there is a genuine, documented reason that cannot be resolved with an array.
- Inline `# shellcheck disable=SC<code>` comments must include a comment explaining why the disable is necessary.

## Pull request checklist

- [ ] Manually tested the affected commands (`gh fzf <cmd>`) with and without extra flags
- [ ] `shellcheck scripts/*.sh` passes with zero warnings
- [ ] Docs updated if new keyboard shortcuts, flags, or configuration options were added
- [ ] New command? Wired into `gh-fzf` entry point and added to `docs/`
