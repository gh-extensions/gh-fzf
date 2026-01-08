#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_issue_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_issue_source_dir/gh_core.sh"

# gh_issue.sh - GitHub Issue commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# issue listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_issue_list()
#
# Interactive fuzzy finder for GitHub issues
#
# DESCRIPTION:
#   Displays a list of GitHub issues in an interactive fuzzy finder (fzf)
#   with various keyboard shortcuts for common issue operations. Shows up to 30
#   most recent issues with detailed information including issue number, title,
#   author, assignees, state, milestone, labels, and last update time.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh issue list (e.g., --state closed, --author @me,
#        --assignee @me, --label bug, --search "query", --limit 50)
#        Flags controlled by gh-fzf (--json, --jq, --template) are filtered out
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#   1 - Failure (no issues found or not in a GitHub repository)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open issue in web browser
#   alt-c     - Comment on issue using editor
#   alt-e     - Edit issue details
#   alt-x     - Close issue
#   alt-r     - Reopen issue
#   alt-a     - Assign issue to self (@me)
#   alt-l     - Add label to issue
#   alt-p     - Pin issue
#   alt-u     - Unpin issue
#   alt-enter - View issue details in terminal
#
# DEPENDENCIES:
#   - gh (GitHub CLI)
#   - fzf (fuzzy finder)
#   - gum (for spinner and logging)
#
# NOTES:
#   - Issue number is extracted from the first column in fzf selections
#   - Issues are sorted by update time (most recent first)
#
# EXAMPLE:
#   gh-fzf issue
#
_gh_issue_list() {
	# Show help if requested
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		gh issue list --help
		return $?
	fi

	local issue_list
	issue_list=$("$_gh_issue_source_dir/gh_issue_cmd.sh" "$@")

	# Check if we got any issues
	if [ -z "$issue_list" ]; then
		gum log --level warn "No GitHub Issues found. Make sure you're in a GitHub repository and have issues available."
		return 1
	fi

	# Transform and present in fzf
	echo "$issue_list" | fzf --ansi "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1.. \
		--footer "$_fzf_icon GitHub Issues" \
		--bind "ctrl-o:execute-silent(gh issue view {1} --web)" \
		--bind "ctrl-r:reload($_gh_issue_source_dir/gh_issue_cmd.sh $*)" \
		--bind "alt-c:execute(gh issue comment {1} --editor)" \
		--bind "alt-e:execute(gh issue edit {1})" \
		--bind "alt-x:execute(gh issue close {1})" \
		--bind "alt-r:execute(gh issue reopen {1})" \
		--bind "alt-a:execute(gh issue edit {1} --add-assignee @me)" \
		--bind "alt-l:execute(gh issue edit {1} --add-label)" \
		--bind "alt-p:execute(gh issue pin {1})" \
		--bind "alt-u:execute(gh issue unpin {1})" \
		--bind "alt-enter:execute-silent($_gh_issue_source_dir/gh_core.sh issue view {1})"
}
