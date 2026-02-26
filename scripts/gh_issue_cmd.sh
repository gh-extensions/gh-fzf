#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -eo pipefail

_gh_issue_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_issue_cmd_source_dir/gh_core.sh"

# gh_issue_cmd.sh - GitHub Issue commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# issue listing and label management functionality.
#
# SUBCOMMANDS:
#   add-label [issue] - Interactively add a label to the specified issue.
#   help              - Display keyboard shortcuts for the issue list.
#   (default)         - List issues (passes all args to gh issue list).
#
# Dependencies from main gh-fzf:
#   - _gh_parse_list_args() (argument parsing function)

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
	local -a _gh_fzf_filtered_args=()
	_gh_parse_list_args _gh_fzf_filtered_args "$@"

	# Set up columns and template
	local issue_columns="number,title,author,assignees,state,milestone,labels,updatedAt"
	local issue_template

	issue_template=$(cat "$_gh_issue_cmd_source_dir/../templates/gh_issue_list.tmpl")

	# Query GitHub for issues with spinner feedback
	gum spin --title "Loading GitHub Issues..." -- \
		gh issue list "${_gh_fzf_filtered_args[@]}" --json "$issue_columns" --template "$issue_template"
}

# _gh_issue_add_label_cmd()
#
# Interactively add a label to a GitHub issue
#
# DESCRIPTION:
#   Fetches available labels for the current repository, presents them via
#   gum choose for interactive selection, then applies the chosen label to
#   the specified issue.
#
# PARAMETERS:
#   $1 - The issue number to label.
#
# RETURNS:
#   0 - Label applied successfully
#   1 - No label selected or operation failed
#
# EXAMPLE:
#   _gh_issue_add_label_cmd 42
#
_gh_issue_add_label_cmd() {
	local issue_number="$1"

	if [ -z "$issue_number" ]; then
		gum log --level error "GitHub Issue number required"
		return 1
	fi

	local label_list
	# Load the label list.
	label_list=$(gum spin --title "Loading GitHub Labels..." --show-output -- gh label list --json name -q '.[].name')

	local label
	# Choose the label.
	label=$(echo "$label_list" | gum choose --header "Add label to GitHub Issue $issue_number:")
	if [ -z "$label" ]; then
		return 1
	fi

	gh issue edit "$issue_number" --add-label "$label"
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
| **`alt-t`** | Add label |
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
#
# SUBCOMMANDS:
#   add-label <issue>  - Interactively pick and apply a label to an issue.
#   help               - Show keyboard shortcut reference.
#   (anything else)    - List issues (forwarded to gh issue list).
#
# EXAMPLE:
#   ./gh_issue_cmd.sh add-label 42
#   ./gh_issue_cmd.sh help
# ------------------------------------------------------------------------------
main() {
	local subcommand="${1:-}"

	case "$subcommand" in
	add-label)
		shift
		_gh_issue_add_label_cmd "$@"
		;;
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
