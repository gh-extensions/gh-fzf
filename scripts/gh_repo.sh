#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_repo_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_repo_source_dir/gh_core.sh"

# gh_repo.sh - GitHub Repository commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# repository listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

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
#   alt-c     - Clone repository to custom directory (if configured)
#   alt-f     - Fork repository and clone to custom directory (if configured)
#   alt-v     - View repository README
#   alt-enter - View repository details in terminal
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
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		gh repo list --help
		return $?
	fi

	local repo
	repo="$1"

	local repo_list
	repo_list=$("$_gh_repo_source_dir/gh_repo_cmd.sh" list "$@")

	# Check if we got any repositories
	if [ -z "$repo_list" ]; then
		gum log --level warn "No GitHub Repositories found. Make sure you're authenticated with GitHub CLI."
		return 1
	fi

	# Build fzf options with user-provided flags
	_gh_fzf_options

	# Transform and present in fzf
	echo "$repo_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1.. \
		--footer "$_fzf_icon GitHub Repositories $_fzf_split $repo" \
		--bind "ctrl-o:execute-silent(gh repo view {1} --web)" \
		--bind "ctrl-r:reload($_gh_repo_source_dir/gh_repo_cmd.sh list $*)" \
		--bind "alt-c:execute-silent($_gh_repo_source_dir/gh_repo_cmd.sh clone {1})" \
		--bind "alt-f:execute-silent($_gh_repo_source_dir/gh_repo_cmd.sh fork {1})" \
		--bind "alt-enter:execute-silent($_gh_repo_source_dir/gh_core.sh repo view {1})"
}
