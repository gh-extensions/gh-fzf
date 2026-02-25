#!/usr/bin/env bash

# Icon used in tmux popup titles
_fzf_icon=" "
# Separator used in fzf display templates
_fzf_split="·"

# fzf execute action: silent (keeps fzf alive) in tmux, blocking otherwise
if [[ -n "$TMUX" ]]; then
	_fzf_execute="execute-silent"
else
	_fzf_execute="execute"
fi

# _gh_fzf_options()
#
# Build fzf options array with user-provided flags
#
# DESCRIPTION:
#   Constructs the fzf options array by combining default options with
#   user-provided flags from GH_FZF_FLAGS environment variable and per-command
#   GH_FZF_<COMMAND>_OPTS environment variables. This function must be called
#   at runtime (not at source time) to pick up flags set by main().
#
#   Precedence order (last wins):
#   1. Default options (defined in code)
#   2. GH_FZF_FLAGS (global, set via CLI)
#   3. GH_FZF_<COMMAND>_OPTS (per-command, highest priority)
#
# PARAMETERS:
#   $1 - Optional command identifier
#        Used to lookup per-command environment variable GH_FZF_${command_id}_OPTS
#
# RETURNS:
#   Sets _fzf_options array with merged options
#
# ENVIRONMENT:
#   GH_FZF_FLAGS - Space-separated string of user fzf flags (set by main entry point)
#   GH_FZF_<COMMAND>_OPTS - Per-command fzf options (e.g., GH_FZF_PR_OPTS)
#
# EXAMPLE:
#   # Call this before using fzf in any service function
#   _gh_fzf_options "PR"
#   echo "$data" | fzf "${_fzf_options[@]}" ...
#
_gh_fzf_options() {
	local command_id="${1:-}"

	# Default fzf options for gh-fzf
	_fzf_options=(
		--ansi
		--header-lines='1'
		--header-border='sharp'
		--footer-border='sharp'
		--input-border='sharp'
		--color='header:blue'
		--color='footer:blue'
		--layout='reverse-list'
		--preview-window='right:40:wrap:hidden'
	)

	# Add user-provided fzf flags (global)
	if [[ -n "${GH_FZF_FLAGS:-}" ]]; then
		local user_flags=()
		read -ra user_flags <<<"$GH_FZF_FLAGS"
		_fzf_options+=("${user_flags[@]}")
	fi

	# Add per-command fzf options (highest precedence)
	if [[ -n "$command_id" ]]; then
		local var_name="GH_FZF_${command_id}_OPTS"
		local cmd_flags="${!var_name:-}"
		if [[ -n "$cmd_flags" ]]; then
			local cmd_flags_array=()
			read -ra cmd_flags_array <<<"$cmd_flags"
			_fzf_options+=("${cmd_flags_array[@]}")
		fi
	fi
}

# _gh_get_repo: Get the current repository in owner/repo format.
#
# Returns the repository name in owner/repo format (e.g., gh-extensions/gh-fzf)
# by querying the GitHub CLI. Returns an empty string if not in a repository
# or if the command fails.
#
# Returns:
#   The repository name in owner/repo format, or empty string on error.
#
# Example:
#   repo=$(_gh_get_repo)
#   # Returns: "gh-extensions/gh-fzf"
_gh_get_repo() {
	gh repo view --json nameWithOwner --template "{{.nameWithOwner}}" 2>/dev/null || echo ""
}

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
		tmux popup -T " $_fzf_icon GitHub $resource $3 " -S "fg=blue" -w 80% -h 80% -d "$PWD" gh "$@"
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
	search)
		echo "Search"
		;;
	esac

}

# _gh_parse_list_args()
#
# Parse arguments, accumulating passthrough flags into a named array
#
# DESCRIPTION:
#   Single-pass parser that strips flags gh-fzf controls internally
#   (--json, --jq, --template and their short forms) and accumulates
#   everything else directly into a caller-supplied array via nameref.
#   Handles both --flag value and --flag=value forms.
#
# PARAMETERS:
#   $1 - Name of caller's array variable to populate (nameref)
#   $@ - Arguments to parse
#
# STRIPPED FLAGS:
#   --json, --jq, -q    - gh-fzf controls JSON output format
#   --template, -t      - gh-fzf controls output template
#
# EXAMPLE:
#   local -a passthrough=()
#   _gh_parse_list_args passthrough --state closed --json custom
#   # passthrough=("--state" "closed")
#
_gh_parse_list_args() {
	local -n _gh_parse_out_ref="$1"
	shift

	local args=("$@")
	local i=0

	while [[ $i -lt ${#args[@]} ]]; do
		case "${args[$i]}" in
		--json | --jq | --template | -q | -t)
			((i += 2))
			continue
			;;
		--json=* | --jq=* | --template=*)
			;;
		*)
			_gh_parse_out_ref+=("${args[$i]}")
			;;
		esac
		((++i))
	done
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to _gh.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	_gh "$@"
fi
