#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

# Icon used in tmux popup titles
_fzf_icon=" "
# Separator used in fzf display templates
_fzf_split="·"

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
	local cmd_id="${1:-}"

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
		--preview-window='right:40:wrap:hidden:border-top'
	)

	# Add user-provided fzf flags (global)
	if [[ -n "${GH_FZF_FLAGS:-}" ]]; then
		local user_flags=()
		eval "user_flags=($GH_FZF_FLAGS)"
		_fzf_options+=("${user_flags[@]}")
	fi

	# Add per-command fzf options (highest precedence)
	if [[ -n "$cmd_id" ]]; then
		local var_name="GH_FZF_${cmd_id}_OPTS"
		local cmd_flags="${!var_name:-}"
		if [[ -n "$cmd_flags" ]]; then
			local cmd_flags_array=()
			eval "cmd_flags_array=($cmd_flags)"
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
		--json=* | --jq=* | --template=*) ;;
		*)
			_gh_parse_out_ref+=("${args[$i]}")
			;;
		esac
		((++i))
	done
}

