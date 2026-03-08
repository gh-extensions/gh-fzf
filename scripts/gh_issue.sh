#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_issue_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_issue_source_dir/gh_core.sh"

# gh_issue.sh - GitHub Issue commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# issue listing and interactive functionality.
#

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
#   ctrl-r    - Reload issue list with current filters
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
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		gh issue list --help
		return $?
	fi

	local gh_issue_repo
	gh_issue_repo=$(_gh_get_repo)

	local gh_issue_list_cmd
	gh_issue_list_cmd="$_gh_issue_source_dir/gh_issue_cmd.sh"

	local gh_issue_list
	gh_issue_list=$("$gh_issue_list_cmd" "$@")

	# Check if we got any issues
	if [ -z "$gh_issue_list" ]; then
		gum log --level warn "No GitHub Issues found. Make sure you're in a GitHub repository and have issues available."
		return 1
	fi

	[ $# -gt 0 ] && gh_issue_list_cmd+="$(printf ' %q' "$@")"

	local gh_issue_footer
	gh_issue_footer="$_fzf_icon GitHub Issues $_fzf_split $gh_issue_repo"

	# Build fzf options with user-provided flags
	_gh_fzf_options "ISSUE"

	# Register tmux bindings only when running inside a tmux session
	if [[ -n "${TMUX:-}" ]]; then
		local gh_tmux_cmd
		gh_tmux_cmd="$_gh_issue_source_dir/gh_tmux_cmd.sh"

		local gh_tmux_title
		gh_tmux_title="$_fzf_icon GitHub Issue {1}"

		_fzf_options+=(--bind "alt-enter:execute-silent($gh_tmux_cmd display-popup $gh_tmux_title gh issue view {1})")
	else
		_fzf_options+=(--bind "alt-enter:execute(gh issue view {1})")
	fi

	# Transform and present in fzf
	echo "$gh_issue_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1.. \
		--footer "$gh_issue_footer" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$_gh_issue_source_dir/gh_issue_cmd.sh preview-help" \
		--bind "load:change-footer($gh_issue_footer)" \
		--bind "ctrl-o:change-footer($gh_issue_footer $_fzf_split Opening in browser...)+execute-silent(gh issue view {1} --web)" \
		--bind "ctrl-r:change-footer($gh_issue_footer $_fzf_split Reloading...)+reload($gh_issue_list_cmd)" \
		--bind "alt-c:execute(gh issue comment {1} --editor)" \
		--bind "alt-e:execute(gh issue edit {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-x:change-footer($gh_issue_footer $_fzf_split Closing issue...)+execute-silent(gh issue close {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-r:change-footer($gh_issue_footer $_fzf_split Reopening issue...)+execute-silent(gh issue reopen {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-a:change-footer($gh_issue_footer $_fzf_split Assigning to @me...)+execute-silent(gh issue edit {1} --add-assignee @me)+reload($gh_issue_list_cmd)" \
		--bind "alt-l:execute($_gh_issue_source_dir/gh_issue_cmd.sh add-label {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-p:change-footer($gh_issue_footer $_fzf_split Pinning issue...)+execute-silent(gh issue pin {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-u:change-footer($gh_issue_footer $_fzf_split Unpinning issue...)+execute-silent(gh issue unpin {1})+reload($gh_issue_list_cmd)" \
		--bind "alt-h:toggle-preview"
}
