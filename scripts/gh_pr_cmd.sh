#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_pr_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_pr_cmd_source_dir/gh_core.sh"

# gh_pr_cmd.sh - GitHub Pull Request commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# pull request listing functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_pr_list_cmd()
#
# List GitHub pull requests
#
# DESCRIPTION:
#   Fetches a list of GitHub pull requests with detailed information including PR
#   number, title, state, branch, milestone, labels, and change statistics.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh pr list (e.g., --state closed, --author @me,
#        --label bug, --search "query", --limit 50)
#
# RETURNS:
#   A formatted string of pull requests, one per line.
#
_gh_pr_list_cmd() {
	local _gh_fzf_filtered_args
	# Filter out arguments that gh-fzf controls
	_gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

	# Set up columns and template
	local pr_columns="number,title,state,headRefName,milestone,updatedAt,labels,additions,deletions,changedFiles,isDraft"
	local pr_template

	pr_template=$(cat "$_gh_pr_cmd_source_dir/../templates/gh_pr_list.tmpl")

	# Query GitHub for pull requests with spinner feedback
	# shellcheck disable=SC2086
	gum spin --title "Loading GitHub Pull Requests..." -- \
		gh pr list $_gh_fzf_filtered_args --json "$pr_columns" --template "$pr_template"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to the function.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	_gh_pr_list_cmd "$@"
fi
