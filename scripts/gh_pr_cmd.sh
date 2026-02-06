#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_pr_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_pr_cmd_source_dir/gh_core.sh"

# gh_pr_cmd.sh - GitHub Pull Request commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# pull request listing functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_pr_list_cmd()
#
# List GitHub pull requests
#
# DESCRIPTION:
#   Fetches a list of GitHub pull requests with detailed information including PR
#   number, title, state, branch, milestone, labels, and change statistics.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh pr list (e.g., --state closed, --author @me,
#        --label bug, --search "query", --limit 50)
#
# RETURNS:
#   A formatted string of pull requests, one per line.
#
_gh_pr_list_cmd() {
	local _gh_fzf_filtered_args
	# Filter out arguments that gh-fzf controls
	_gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

	# Set up columns and template
	local pr_columns="number,title,state,headRefName,milestone,updatedAt,labels,additions,deletions,changedFiles,isDraft"
	local pr_template

	pr_template=$(cat "$_gh_pr_cmd_source_dir/../templates/gh_pr_list.tmpl")

	# Query GitHub for pull requests with spinner feedback
	# shellcheck disable=SC2086
	gum spin --title "Loading GitHub Pull Requests..." -- \
		gh pr list $_gh_fzf_filtered_args --json "$pr_columns" --template "$pr_template"
}

# _gh_pr_help()
#
# Display keyboard shortcuts for PR list
#
# DESCRIPTION:
#   Outputs formatted help text showing available keyboard shortcuts
#   for the PR list. Designed to be displayed in fzf preview window.
#
# RETURNS:
#   Formatted help text with shortcuts and tips
#
_gh_pr_help() {
	gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload list |
| **`ctrl-w`** | View checks (web) |
| **`alt-c`** | Comment on PR |
| **`alt-a`** | Approve PR |
| **`alt-e`** | Edit PR |
| **`alt-r`** | Mark as ready |
| **`alt-x`** | Close PR |
| **`alt-m`** | Merge PR |
| **`alt-enter`** | View details |
| **`alt-w`** | Watch checks |
| **`alt-k`** | View checks |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |
EOF
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate function.
# ------------------------------------------------------------------------------
main() {
	local subcommand="$1"

	case "$subcommand" in
	help)
		_gh_pr_help
		;;
	*)
		_gh_pr_list_cmd "$@"
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
