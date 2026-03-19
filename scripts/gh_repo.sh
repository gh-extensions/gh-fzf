#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_repo_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_repo_source_dir/gh_core.sh"

# gh_repo.sh - GitHub Repository commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# repository listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - _gh_parse_list_args() (argument parsing function)

# _gh_repo_list()
#
# Interactive fuzzy finder for GitHub repositories
#
# DESCRIPTION:
#   Displays a list of GitHub repositories in an interactive fuzzy finder (fzf)
#   with various keyboard shortcuts for common repository operations. Shows up to 30
#   most recent repositories with detailed information including name, description,
#   stars, primary language, visibility, and last update time.
#
# PARAMETERS:
#   $@ - Optional owner and flags to pass to gh repo list (e.g., octocat, --language Go,
#        --visibility public, --limit 50)
#        Flags controlled by gh-fzf (--json, --jq, --template) are filtered out
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#   1 - Failure (no repositories found or not authenticated)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open repository in web browser
#   ctrl-r    - Reload repository list with current filters
#   alt-c     - Clone repository to custom directory (if configured)
#   alt-f     - Fork repository and clone to custom directory (if configured)
#   alt-v - View repository details in terminal
#
# DEPENDENCIES:
#   - gh (GitHub CLI)
#   - fzf (fuzzy finder)
#   - gum (for spinner and logging)
#
# NOTES:
#   - Repository name is extracted from the first column in fzf selections
#   - Repositories are sorted by update time (most recent first)
#   - Supports optional [owner] argument: gh fzf repo <owner>
#
# EXAMPLE:
#   gh-fzf repo
#   gh-fzf repo octocat
#   gh-fzf repo --language Go
#
_gh_repo_list() {
	# Show help if requested
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		gh repo list --help
		return $?
	fi

	# Extract repo owner for footer (first non-flag arg, if any)
	local gh_repo_owner=""
	if [[ -n "${1:-}" && "${1:-}" != -* ]]; then
		gh_repo_owner="$1"
	fi

	local gh_repo_list_cmd
	gh_repo_list_cmd="$_gh_repo_source_dir/gh_repo_cmd.sh"

	local gh_repo_list
	gh_repo_list=$("$gh_repo_list_cmd" list "$@")

	# Check if we got any repositories
	if [ -z "$gh_repo_list" ]; then
		gum log --level warn "No GitHub Repositories found. Make sure you're authenticated with GitHub CLI."
		return 1
	fi

	gh_repo_list_cmd+=" list"
	[ $# -gt 0 ] && gh_repo_list_cmd+="$(printf ' %q' "$@")"

	local gh_repo_footer
	gh_repo_footer="$_fzf_icon GitHub Repositories $_fzf_split $gh_repo_owner"

	# Build fzf options with user-provided flags
	_gh_fzf_options "REPO"

	# Register tmux bindings only when running inside a tmux session
	if [[ -n "${TMUX:-}" ]]; then
		local gh_tmux_cmd
		gh_tmux_cmd="$_gh_repo_source_dir/gh_tmux_cmd.sh"

		local gh_tmux_title
		gh_tmux_title="$_fzf_icon GitHub Repository {1}"

		_fzf_options+=(--bind "alt-v:execute-silent($gh_tmux_cmd display-popup '$gh_tmux_title' gh repo view {1})")
	else
		_fzf_options+=(--bind "alt-v:execute(gh repo view {1})")
	fi

	# Transform and present in fzf
	echo "$gh_repo_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1.. \
		--footer "$gh_repo_footer" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$_gh_repo_source_dir/gh_repo_cmd.sh preview-help" \
		--bind "load:change-footer($gh_repo_footer)" \
		--bind "ctrl-o:change-footer($gh_repo_footer $_fzf_split Opening in browser...)+execute-silent(gh repo view {1} --web)" \
		--bind "ctrl-r:change-footer($gh_repo_footer $_fzf_split Reloading...)+reload($gh_repo_list_cmd)" \
		--bind "alt-c:execute($_gh_repo_source_dir/gh_repo_cmd.sh clone {1})" \
		--bind "alt-f:execute($_gh_repo_source_dir/gh_repo_cmd.sh fork {1})" \
		--bind "alt-h:toggle-preview"
}
