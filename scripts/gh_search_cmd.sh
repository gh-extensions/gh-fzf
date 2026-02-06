#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_search_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_search_cmd_source_dir/gh_core.sh"

# gh_search_cmd.sh - GitHub Search commands for gh-fzf
#
# This file provides search functionality across GitHub (repositories, issues, PRs)
# using the `gh search` command with live/dynamic updates in fzf.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)

# _gh_search_repos_cmd()
#
# Search GitHub repositories
#
# DESCRIPTION:
#   Searches for GitHub repositories using `gh search repos` with the provided query.
#   Returns formatted results using a template. Handles empty queries gracefully.
#
# PARAMETERS:
#   $1 - Search query (can be empty)
#
# RETURNS:
#   Formatted list of repositories, one per line, or a helpful message if query is empty
#
_gh_search_repos_cmd() {
	local query="$1"

	# Handle empty query
	if [ -z "$query" ]; then
		echo "Type to search repositories across GitHub..."
		return 0
	fi

	# Load template
	local search_template
	search_template=$(cat "$_gh_search_cmd_source_dir/../templates/gh_search_repos.tmpl")

	# Execute search (without spinner - would interfere with live updates)
	# shellcheck disable=SC2086
	gh search repos "$query" \
		--limit 30 \
		--json "fullName,description,stargazersCount,language,updatedAt" \
		--template "$search_template" 2>&1 || {
		echo "Search failed. Try a different query or check your network connection."
		return 0
	}
}

# _gh_search_issues_cmd()
#
# Search GitHub issues
#
# DESCRIPTION:
#   Searches for GitHub issues using `gh search issues` with the provided query.
#   Returns formatted results including repository context.
#
# PARAMETERS:
#   $1 - Search query (can be empty)
#
# RETURNS:
#   Formatted list of issues, one per line, or a helpful message if query is empty
#
_gh_search_issues_cmd() {
	local query="$1"

	# Handle empty query
	if [ -z "$query" ]; then
		echo "Type to search issues across GitHub..."
		return 0
	fi

	# Load template
	local search_template
	search_template=$(cat "$_gh_search_cmd_source_dir/../templates/gh_search_issues.tmpl")

	# Execute search
	# shellcheck disable=SC2086
	gh search issues "$query" \
		--limit 30 \
		--json "number,title,repository,state,author,createdAt" \
		--template "$search_template" 2>&1 || {
		echo "Search failed. Try a different query or check your network connection."
		return 0
	}
}

# _gh_search_prs_cmd()
#
# Search GitHub pull requests
#
# DESCRIPTION:
#   Searches for GitHub PRs using `gh search prs` with the provided query.
#   Returns formatted results including repository context.
#
# PARAMETERS:
#   $1 - Search query (can be empty)
#
# RETURNS:
#   Formatted list of PRs, one per line, or a helpful message if query is empty
#
_gh_search_prs_cmd() {
	local query="$1"

	# Handle empty query
	if [ -z "$query" ]; then
		echo "Type to search pull requests across GitHub..."
		return 0
	fi

	# Load template
	local search_template
	search_template=$(cat "$_gh_search_cmd_source_dir/../templates/gh_search_prs.tmpl")

	# Execute search
	# shellcheck disable=SC2086
	gh search prs "$query" \
		--limit 30 \
		--json "number,title,repository,state,author,isDraft,createdAt" \
		--template "$search_template" 2>&1 || {
		echo "Search failed. Try a different query or check your network connection."
		return 0
	}
}

# _gh_search_help()
#
# Display keyboard shortcuts for search commands
#
# DESCRIPTION:
#   Outputs formatted help text showing available keyboard shortcuts for
#   the specified search type. Designed to be displayed in fzf preview window.
#
# PARAMETERS:
#   $1 - Search type (repos, issues, prs)
#
# RETURNS:
#   Formatted help text with shortcuts and search tips
#
_gh_search_help() {
	local search_type="$1"

	case "$search_type" in
	repos | repositories)
		gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-c`** | Clone repository |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public repositories
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
		;;
	issues)
		gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-c`** | Comment on issue |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public issues
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
		;;
	prs | pull-requests)
		gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-c`** | Comment on PR |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public PRs
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
		;;
	*)
		echo "Unknown search type: $search_type"
		;;
	esac
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate search function
# based on the first argument (search type).
# ------------------------------------------------------------------------------
main() {
	local search_type="$1"
	shift

	case "$search_type" in
	repos | repositories)
		_gh_search_repos_cmd "$@"
		;;
	issues)
		_gh_search_issues_cmd "$@"
		;;
	prs | pull-requests)
		_gh_search_prs_cmd "$@"
		;;
	help)
		_gh_search_help "$@"
		;;
	*)
		gum log --level error "Unknown search type '$search_type'"
		gum log --level info "Available types: repos, issues, prs"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
