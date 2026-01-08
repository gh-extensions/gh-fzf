#!/usr/bin/env bash

_fzf_icon=" "

_fzf_options=(
	--ansi
	--border='none'
	--header-lines='1'
	--header-border='sharp'
	--footer-border='sharp'
	--input-border='sharp'
	--color='header:blue'
	--color='footer:blue'
	--layout='reverse-list'
)

# _gh: A wrapper function for the `gh` CLI tool.
#
# This function conditionally calls the `gh` command-line tool, either directly
# or within a `tmux popup` window, depending on the `TMUX` environment variable.
#
# Arguments:
#   $@: All arguments are passed directly to the `gh` command.
#
# Behavior:
#   - If `TMUX` is set, it opens a `tmux popup` with the `gh` command output.
#     The popup title includes the GitHub resource type (e.g., "Pull Request").
#   - If `TMUX` is not set, it executes `gh` directly in the current shell.
_gh() {
	if [[ -z "$TMUX" ]]; then
		gh "$@"
	else
		local resource
		resource=$(_gh_resource "$1")
		tmux popup -T " $_fzf_icon GitHub $resource $3 " -w 80% -h 80% -d "$PWD" gh "$@"
	fi
}

# _gh_resource: Maps a short resource type to its full descriptive name.
#
# This function takes an abbreviated GitHub resource type (e.g., 'pr', 'repo')
# and echoes its corresponding full name (e.g., 'Pull Request', 'Repository').
# It is used primarily for display purposes, such as in tmux popup titles.
#
# Arguments:
#   $1: The abbreviated resource type (e.g., "pr", "repo", "issue", "run").
#
# Returns:
#   The full descriptive name of the resource type.
_gh_resource() {
	local resource_type="$1"

	case "$resource_type" in
	pr)
		echo "Pull Request"
		;;
	repo)
		echo "Repository"
		;;
	issue)
		echo "Issue"
		;;
	run)
		echo "Run"
		;;
	esac

}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to hsdk-env.
# This enables tmux integration and scripted usage.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	_gh "$@"
fi
