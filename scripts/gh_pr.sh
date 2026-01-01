#!/bin/bash

_gh_pr_source_dir=$(dirname "${BASH_SOURCE[0]}")

# gh_pr.sh - GitHub Pull Request commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# pull request listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

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
#   enter    - View PR details in terminal
#   ctrl-o   - Open PR in web browser
#   ctrl-w   - View PR checks in web browser
#   alt-c    - Comment on PR using editor
#   alt-e    - Edit PR details
#   alt-x    - Close PR
#   alt-r    - Reopen PR
#   alt-m    - Merge PR (with review and delete branch)
#   alt-y    - Approve PR with "LGTM" comment
#   alt-w    - Watch PR checks in terminal
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
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		gh pr list --help
		return $?
	fi

	local _gh_fzf_filtered_args
	# Filter out arguments that gh-fzf controls
	_gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

	# Set up columns and template
	local pr_columns="number,title,state,headRefName,milestone,updatedAt,labels,additions,deletions,changedFiles,isDraft"
	local pr_template
	local pr_list

	pr_template=$(cat "$_gh_pr_source_dir/../templates/gh_pr_list.tmpl")

	# Query GitHub for pull requests with spinner feedback
	# shellcheck disable=SC2086
	pr_list=$(gum spin --title "Loading GitHub Pull Requests..." -- \
		gh pr list $_gh_fzf_filtered_args --json "$pr_columns" --template "$pr_template")

	# Check if we got any pull requests
	if [ -z "$pr_list" ]; then
		gum log --level warn "No GitHub Pull Requests found. Make sure you're in a GitHub repository and have pull requests available."
		return 1
	fi

	# Transform and present in fzf
	echo "$pr_list" | fzf --ansi \
		--with-nth 1.. \
		--accept-nth 1 \
		--header "  GitHub Pull Requests" \
		--header-lines 1 \
		--color header:blue \
		--bind "enter:execute(gh pr view {1})+abort" \
		--bind "ctrl-o:execute-silent(gh pr view {1} --web)" \
		--bind "ctrl-w:execute-silent(gh pr checks {1} --web)" \
		--bind "alt-c:execute(gh pr comment {1} --editor)+abort" \
		--bind "alt-e:execute(gh pr edit {1})+abort" \
		--bind "alt-x:execute(gh pr close {1})+abort" \
		--bind "alt-r:execute(gh pr reopen {1})+abort" \
		--bind "alt-m:execute(gh pr merge -r -d {1})+abort" \
		--bind "alt-y:execute(gh pr review {1} --approve -c 'LGTM')+abort" \
		--bind "alt-w:execute(gh pr checks {1} --watch)+abort"
}
