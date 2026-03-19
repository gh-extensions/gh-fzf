#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_run_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_run_source_dir/gh_core.sh"

# gh_run.sh - GitHub Workflow Run commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# workflow run listing and interactive functionality.
#

# _gh_run_list()
#
# Interactive fuzzy finder for GitHub workflow runs
#
# DESCRIPTION:
#   Displays a list of GitHub workflow runs in an interactive fuzzy finder (fzf)
#   with various keyboard shortcuts for common run operations. Shows up to 30
#   most recent workflow runs with detailed information including run date,
#   trigger event, title, branch, run ID, conclusion status, and workflow name.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh run list (e.g., --status success, --branch main,
#        --workflow "CI", --limit 50)
#        Flags controlled by gh-fzf (--json, --jq, --template) are filtered out
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#   1 - Failure (no workflow runs found or not in a GitHub repository)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open run in web browser
#   ctrl-r    - Reload run list with current filters
#   alt-x     - Cancel run
#   alt-r     - Rerun workflow
#   alt-l     - View run logs in gum pager
#   alt-d     - Download run artifacts
#   alt-v - View run details in terminal
#   alt-w     - Watch run progress in terminal
#
# DEPENDENCIES:
#   - gh (GitHub CLI)
#   - fzf (fuzzy finder)
#   - gum (for spinner and logging)
#
# NOTES:
#   - Run ID is extracted from the last column (-1) in fzf selections
#   - Runs are sorted by update time (most recent first)
#
# EXAMPLE:
#   gh-fzf run
#
_gh_run_list() {
	# Show help if requested
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		gh run list --help
		return $?
	fi

	local gh_run_repo
	gh_run_repo=$(_gh_get_repo)

	local gh_run_list_cmd
	gh_run_list_cmd="$_gh_run_source_dir/gh_run_cmd.sh"

	local gh_run_list
	gh_run_list=$("$gh_run_list_cmd" "$@")

	# Check if we got any runs
	if [ -z "$gh_run_list" ]; then
		gum log --level warn "No GitHub Runs found. Make sure you're in a GitHub repository and have workflow runs available."
		return 1
	fi

	[ $# -gt 0 ] && gh_run_list_cmd+="$(printf ' %q' "$@")"

	local gh_run_footer
	gh_run_footer="$_fzf_icon GitHub Runs $_fzf_split $gh_run_repo"

	# Build fzf options with user-provided flags
	_gh_fzf_options "RUN"

	# Register tmux bindings only when running inside a tmux session
	if [[ -n "${TMUX:-}" ]]; then
		local gh_tmux_cmd
		gh_tmux_cmd="$_gh_run_source_dir/gh_tmux_cmd.sh"

		local gh_tmux_title
		gh_tmux_title="$_fzf_icon GitHub Run {-1}"

		_fzf_options+=(--bind "alt-v:execute-silent($gh_tmux_cmd display-popup '$gh_tmux_title' gh run view {-1})")
		_fzf_options+=(--bind "alt-w:execute-silent($gh_tmux_cmd display-popup '$gh_tmux_title' gh run watch {-1})")
	else
		_fzf_options+=(--bind "alt-v:execute(gh run view {-1})")
		_fzf_options+=(--bind "alt-w:execute(gh run watch {-1})")
	fi

	# Transform and present in fzf
	echo "$gh_run_list" | fzf "${_fzf_options[@]}" \
		--accept-nth -1 --with-nth 1.. \
		--footer "$gh_run_footer" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$_gh_run_source_dir/gh_run_cmd.sh preview-help" \
		--bind "load:change-footer($gh_run_footer)" \
		--bind "ctrl-o:change-footer($gh_run_footer $_fzf_split Opening in browser...)+execute-silent(gh run view {-1} --web)" \
		--bind "ctrl-r:change-footer($gh_run_footer $_fzf_split Reloading...)+reload($gh_run_list_cmd)" \
		--bind "alt-x:change-footer($gh_run_footer $_fzf_split Cancelling run...)+execute-silent(gh run cancel {-1})+reload($gh_run_list_cmd)" \
		--bind "alt-r:change-footer($gh_run_footer $_fzf_split Rerunning...)+execute-silent(gh run rerun {-1})+reload($gh_run_list_cmd)" \
		--bind "alt-d:change-footer($gh_run_footer $_fzf_split Downloading artifacts...)+execute-silent(gh run download {-1})" \
		--bind "alt-l:execute(gh run view {-1} --log | gum pager)" \
		--bind "alt-h:toggle-preview"
}
