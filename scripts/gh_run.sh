#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_run_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_run_source_dir/gh_core.sh"

# gh_run.sh - GitHub Workflow Run commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# workflow run listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

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
#   alt-x     - Cancel run
#   alt-r     - Rerun workflow
#   alt-l     - View run logs in terminal
#   alt-d     - Download run artifacts
#   alt-enter - View run details in terminal
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
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		gh run list --help
		return $?
	fi

	local run_list
	run_list=$("$_gh_run_source_dir/gh_run_cmd.sh" "$@")

	# Check if we got any runs
	if [ -z "$run_list" ]; then
		gum log --level warn "No GitHub Runs found. Make sure you're in a GitHub repository and have workflow runs available."
		return 1
	fi

	# Transform and present in fzf
	echo "$run_list" | fzf "${_fzf_options[@]}" \
		--accept-nth -1 --with-nth 1.. \
		--footer "$_fzf_icon GitHub Runs" \
		--bind "ctrl-o:execute-silent(gh run view {-1} --web)" \
		--bind "ctrl-r:reload($_gh_run_source_dir/gh_run_cmd.sh $*)" \
		--bind "alt-x:execute(gh run cancel {-1})" \
		--bind "alt-r:execute(gh run rerun {-1})" \
		--bind "alt-d:execute(gh run download {-1})" \
		--bind "alt-enter:execute-silent($_gh_run_source_dir/gh_core.sh run view {-1})" \
		--bind "alt-l:execute-silent($_gh_run_source_dir/gh_core.sh run view {-1} --log)" \
		--bind "alt-w:execute-silent($_gh_run_source_dir/gh_core.sh run watch {-1})"
}
