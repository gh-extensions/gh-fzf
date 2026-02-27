#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_pr_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_pr_source_dir/gh_core.sh"

# gh_pr.sh - GitHub Pull Request commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# pull request listing and interactive functionality.
#

# _gh_pr_list()
#
# Interactive fuzzy finder for GitHub pull requests
#
# DESCRIPTION:
#   Displays a list of GitHub pull requests in an interactive fuzzy finder (fzf)
#   with various keyboard shortcuts for common PR operations. Shows up to 30
#   most recent pull requests with detailed information including PR number,
#   title, state, branch, milestone, labels, and change statistics.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh pr list (e.g., --state closed, --author @me,
#        --label bug, --search "query", --limit 50)
#        Flags controlled by gh-fzf (--json, --jq, --template) are filtered out
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#   1 - Failure (no pull requests found or not in a GitHub repository)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open PR in web browser
#   ctrl-r    - Reload PR list with current filters
#   ctrl-w    - View PR checks in web browser
#   alt-c     - Comment on PR using editor
#   alt-a     - Approve PR with "LGTM" comment
#   alt-e     - Edit PR details
#   alt-r     - Mark PR as ready for review
#   alt-x     - Close PR
#   alt-m     - Merge PR (with review and delete branch)
#   alt-enter - View PR details in terminal
#   alt-w     - Watch PR checks in terminal
#   alt-k     - View PR checks in terminal
#   alt-E     - AI: explain PR (requires gh-fzf.ai=enabled)
#   alt-R     - AI: review PR (requires gh-fzf.ai=enabled)
#
# DEPENDENCIES:
#   - gh (GitHub CLI)
#   - fzf (fuzzy finder)
#   - gum (for spinner and logging)
#
# EXAMPLE:
#   gh-fzf pr
#
_gh_pr_list() {
	# Show help if requested
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		gh pr list --help
		return $?
	fi

	local gh_pr_repo
	gh_pr_repo=$(_gh_get_repo)

	local gh_pr_list
	gh_pr_list=$("$_gh_pr_source_dir/gh_pr_cmd.sh" "$@")

	# Check if we got any pull requests
	if [ -z "$gh_pr_list" ]; then
		gum log --level warn "No GitHub Pull Requests found. Make sure you're in a GitHub repository and have pull requests available."
		return 1
	fi

	local gh_pr_list_reload
	gh_pr_list_reload="$_gh_pr_source_dir/gh_pr_cmd.sh$(printf ' %q' "$@")"

	# Build fzf options with user-provided flags
	_gh_fzf_options "PR"

	if _gh_ai_enabled; then
		_fzf_options+=(--bind "alt-E:execute(gh ai pr explain {1} | gum pager)")
		_fzf_options+=(--bind "alt-R:execute(gh ai pr review {1})")
	fi

	# Transform and present in fzf
	echo "$gh_pr_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1.. \
		--footer "$_fzf_icon GitHub Pull Requests $_fzf_split $gh_pr_repo" \
		--preview "$_gh_pr_source_dir/gh_pr_cmd.sh preview-help" \
		--bind "ctrl-o:execute-silent(gh pr view {1} --web)" \
		--bind "ctrl-r:reload($gh_pr_list_reload)" \
		--bind "ctrl-w:execute-silent(gh pr checks {1} --web)" \
		--bind "alt-c:execute(gh pr comment {1} --editor)" \
		--bind "alt-a:execute-silent(gh pr review {1} --approve -c 'LGTM')+reload($gh_pr_list_reload)" \
		--bind "alt-e:execute-silent(gh pr edit {1})+reload($gh_pr_list_reload)" \
		--bind "alt-r:execute-silent(gh pr ready {1})+reload($gh_pr_list_reload)" \
		--bind "alt-x:execute-silent(gh pr close {1})+reload($gh_pr_list_reload)" \
		--bind "alt-m:execute-silent(gh pr merge -r -d {1})+reload($gh_pr_list_reload)" \
		--bind "alt-enter:$_fzf_execute($_gh_pr_source_dir/gh_core.sh pr view {1})" \
		--bind "alt-w:$_fzf_execute($_gh_pr_source_dir/gh_core.sh pr checks {1} --watch)" \
		--bind "alt-k:$_fzf_execute($_gh_pr_source_dir/gh_core.sh pr checks {1})" \
		--bind "alt-h:toggle-preview"
}
