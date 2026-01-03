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
#   enter    - View run details in terminal
#   ctrl-o   - Open run in web browser
#   ctrl-w   - View run in web browser (same as ctrl-o)
#   alt-x    - Cancel run
#   alt-r    - Rerun workflow
#   alt-l    - View run logs in terminal
#   alt-d    - Download run artifacts
#   alt-w    - Watch run progress in terminal
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

	local _gh_fzf_filtered_args
	# Filter out arguments that gh-fzf controls
	_gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

	# Set up columns and template
	local run_columns="updatedAt,event,displayTitle,headBranch,databaseId,conclusion,status,name"
	local run_template
	local run_list

	run_template=$(cat "$_gh_run_source_dir/../templates/gh_run_list.tmpl")

	# Query GitHub for workflow runs with spinner feedback
	# shellcheck disable=SC2086
	run_list=$(gum spin --title "Loading GitHub Runs..." -- \
		gh run list $_gh_fzf_filtered_args --json "$run_columns" --template "$run_template")

	# Check if we got any runs
	if [ -z "$run_list" ]; then
		gum log --level warn "No GitHub Runs found. Make sure you're in a GitHub repository and have workflow runs available."
		return 1
	fi

	# Transform and present in fzf
	echo "$run_list" | fzf "${_fzf_options[@]}" \
		--with-nth 1.. --accept-nth -1 \
		--footer "$_fzf_icon GitHub Runs" \
		--bind "enter:execute(gh run view {-1})+abort" \
		--bind "ctrl-o:execute-silent(gh run view {-1} --web)" \
		--bind "ctrl-w:execute-silent(gh run view {-1} --web)" \
		--bind "alt-x:execute(gh run cancel {-1})+abort" \
		--bind "alt-r:execute(gh run rerun {-1})+abort" \
		--bind "alt-l:execute(gh run view --log {-1})+abort" \
		--bind "alt-d:execute(gh run download {-1})+abort" \
		--bind "alt-w:execute(gh run watch {-1})+abort"
}
