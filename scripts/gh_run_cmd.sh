#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_run_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_run_cmd_source_dir/gh_core.sh"

# gh_run_cmd.sh - GitHub Workflow Run commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# workflow run listing functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_run_list_cmd()
#
# List GitHub workflow runs
#
# DESCRIPTION:
#   Fetches a list of GitHub workflow runs with detailed information.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh run list
#
# RETURNS:
#   A formatted string of workflow runs, one per line.
#
_gh_run_list_cmd() {
    local _gh_fzf_filtered_args
    # Filter out arguments that gh-fzf controls
    _gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

    # Set up columns and template
    local run_columns="updatedAt,event,displayTitle,headBranch,databaseId,conclusion,status,name"
    local run_template

    run_template=$(cat "$_gh_run_cmd_source_dir/../templates/gh_run_list.tmpl")

    # Query GitHub for workflow runs with spinner feedback
    # shellcheck disable=SC2086
    gum spin --title "Loading GitHub Runs..." -- \
        gh run list $_gh_fzf_filtered_args --json "$run_columns" --template "$run_template"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to the function.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _gh_run_list_cmd "$@"
fi
