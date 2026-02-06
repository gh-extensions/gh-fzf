#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_issue_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_issue_cmd_source_dir/gh_core.sh"

# gh_issue_cmd.sh - GitHub Issue commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# issue listing functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_issue_list_cmd()
#
# List GitHub issues
#
# DESCRIPTION:
#   Fetches a list of GitHub issues with detailed information including issue
#   number, title, author, assignees, state, milestone, labels, and last
#   update time.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh issue list
#
# RETURNS:
#   A formatted string of issues, one per line.
#
_gh_issue_list_cmd() {
    local _gh_fzf_filtered_args
    # Filter out arguments that gh-fzf controls
    _gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

    # Set up columns and template
    local issue_columns="number,title,author,assignees,state,milestone,labels,updatedAt"
    local issue_template

    issue_template=$(cat "$_gh_issue_cmd_source_dir/../templates/gh_issue_list.tmpl")

    # Query GitHub for issues with spinner feedback
    # shellcheck disable=SC2086
    gum spin --title "Loading GitHub Issues..." -- \
        gh issue list $_gh_fzf_filtered_args --json "$issue_columns" --template "$issue_template"
}

# _gh_issue_help()
#
# Display keyboard shortcuts for issue list
#
# DESCRIPTION:
#   Outputs formatted help text showing available keyboard shortcuts
#   for the issue list. Designed to be displayed in fzf preview window.
#
# RETURNS:
#   Formatted help text with shortcuts and tips
#
_gh_issue_help() {
	gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload list |
| **`alt-c`** | Comment on issue |
| **`alt-e`** | Edit issue |
| **`alt-x`** | Close issue |
| **`alt-r`** | Reopen issue |
| **`alt-a`** | Assign to me |
| **`alt-l`** | Add label |
| **`alt-p`** | Pin issue |
| **`alt-u`** | Unpin issue |
| **`alt-enter`** | View details |
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
		_gh_issue_help
		;;
	*)
		_gh_issue_list_cmd "$@"
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
