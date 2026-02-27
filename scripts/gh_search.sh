#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_search_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_search_source_dir/gh_core.sh"

# gh_search.sh - GitHub Search commands for gh-fzf
#
# This file provides interactive search functionality for GitHub using fzf's
# dynamic reload pattern. Searches update live as the user types.
#

# _gh_search_repos_list()
#
# Interactive repository search
#
# DESCRIPTION:
#   Provides an interactive search interface for GitHub repositories using fzf
#   with dynamic reload. Results update as the user types their query.
#
# PARAMETERS:
#   $1 - Optional initial search query
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open repository in web browser
#   ctrl-r    - Manual reload with current query
#   alt-g     - Clone repository
#   alt-enter - View repository details in terminal
#
_gh_search_repos_preview_help() {
	gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-g`** | Clone repository |
| **`alt-enter`** | View details in terminal |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public repositories
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
}

_gh_search_repos_list() {
	local search_query
	search_query=$(printf '%q' "${1:-}")

	# Build fzf options with user-provided flags
	_gh_fzf_options "SEARCH_REPO"

	# Note: Using --disabled to disable fzf's fuzzy matching, allowing us to
	# pass the query directly to GitHub's search API
	fzf "${_fzf_options[@]}" \
		--disabled \
		--footer "$_fzf_icon GitHub Repositories" \
		--preview "$(declare -f _gh_search_repos_preview_help); _gh_search_repos_preview_help" \
		--bind "start:reload:$_gh_search_source_dir/gh_search_cmd.sh repos $search_query" \
		--bind "change:reload:sleep 0.1; $_gh_search_source_dir/gh_search_cmd.sh repos {q} || true" \
		--bind "ctrl-o:execute-silent(gh repo view {1} --web)" \
		--bind "ctrl-r:reload($_gh_search_source_dir/gh_search_cmd.sh repos {q})" \
		--bind "alt-g:execute($_gh_search_source_dir/gh_repo_cmd.sh clone {1})" \
		--bind "alt-enter:$_fzf_execute($_gh_search_source_dir/gh_core.sh repo view {1})" \
		--bind "alt-h:toggle-preview"
}

# _gh_search_issues_list()
#
# Interactive issue search
#
# DESCRIPTION:
#   Provides an interactive search interface for GitHub issues using fzf
#   with dynamic reload. Results update as the user types their query.
#   Issues from all repositories are searched.
#
# PARAMETERS:
#   $1 - Optional initial search query
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open issue in web browser
#   ctrl-r    - Manual reload with current query
#   alt-c     - Comment on issue
#   alt-enter - View issue details in terminal
#
_gh_search_issues_preview_help() {
	gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-c`** | Comment on issue |
| **`alt-enter`** | View details in terminal |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public issues
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
}

_gh_search_issues_list() {
	local search_query
	search_query=$(printf '%q' "${1:-}")

	# Build fzf options with user-provided flags
	_gh_fzf_options "SEARCH_ISSUE"

	fzf "${_fzf_options[@]}" \
		--disabled \
		--footer "$_fzf_icon GitHub Issues" \
		--preview "$(declare -f _gh_search_issues_preview_help); _gh_search_issues_preview_help" \
		--bind "start:reload:$_gh_search_source_dir/gh_search_cmd.sh issues $search_query" \
		--bind "change:reload:sleep 0.1; $_gh_search_source_dir/gh_search_cmd.sh issues {q} || true" \
		--bind "ctrl-o:execute-silent(gh issue view {1} --repo {2} --web)" \
		--bind "ctrl-r:reload($_gh_search_source_dir/gh_search_cmd.sh issues {q})" \
		--bind "alt-c:execute(gh issue comment {1} --repo {2} --editor)" \
		--bind "alt-enter:$_fzf_execute($_gh_search_source_dir/gh_core.sh issue view {1} --repo {2})" \
		--bind "alt-h:toggle-preview"
}

# _gh_search_prs_list()
#
# Interactive pull request search
#
# DESCRIPTION:
#   Provides an interactive search interface for GitHub PRs using fzf
#   with dynamic reload. Results update as the user types their query.
#   PRs from all repositories are searched.
#
# PARAMETERS:
#   $1 - Optional initial search query
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open PR in web browser
#   ctrl-r    - Manual reload with current query
#   alt-c     - Comment on PR
#   alt-enter - View PR details in terminal
#   alt-E     - AI: explain PR (requires gh-fzf.ai=enabled)
#   alt-R     - AI: review PR (requires gh-fzf.ai=enabled)
#
_gh_search_prs_preview_help() {
	gum format <<'EOF'
# Help

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload search |
| **`alt-c`** | Comment on PR |
| **`alt-enter`** | View details in terminal |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |

## Search Tips

- Search all public PRs
- Results update as you type
- Use GitHub search syntax
- `ctrl-r` refreshes results
EOF
}

_gh_search_prs_list() {
	local search_query
	search_query=$(printf '%q' "${1:-}")

	# Build fzf options with user-provided flags
	_gh_fzf_options "SEARCH_PR"

	if _gh_ai_enabled; then
		_fzf_options+=(--bind "alt-E:execute(gh ai pr explain {1} --repo {2} | gum pager)")
		_fzf_options+=(--bind "alt-R:execute(gh ai pr review {1} --repo {2})")
	fi

	fzf "${_fzf_options[@]}" --disabled \
		--footer "$_fzf_icon GitHub Pull Requests" \
		--preview "$(declare -f _gh_search_prs_preview_help); _gh_search_prs_preview_help" \
		--bind "start:reload:$_gh_search_source_dir/gh_search_cmd.sh prs $search_query" \
		--bind "change:reload:sleep 0.1; $_gh_search_source_dir/gh_search_cmd.sh prs {q} || true" \
		--bind "ctrl-o:execute-silent(gh pr view {1} --repo {2} --web)" \
		--bind "ctrl-r:reload($_gh_search_source_dir/gh_search_cmd.sh prs {q})" \
		--bind "alt-c:execute(gh pr comment {1} --repo {2} --editor)" \
		--bind "alt-enter:$_fzf_execute($_gh_search_source_dir/gh_core.sh pr view {1} --repo {2})" \
		--bind "alt-h:toggle-preview"
}

# _gh_search_list()
#
# Main dispatcher for search commands
#
# DESCRIPTION:
#   Routes search commands to the appropriate search type handler.
#   Validates the search type and shows help if needed.
#
# PARAMETERS:
#   $1 - Search type (repos|issues|prs)
#   $@ - Additional arguments (initial query, etc.)
#
# RETURNS:
#   0 - Success
#   1 - Error (unknown search type)
#
_gh_search_list() {
	local search_type="${1:-}"
	shift || true

	# Show help if requested
	if [[ "$search_type" == "--help" || "$search_type" == "-h" ]]; then
		cat <<'EOF'
gh-fzf search - Interactive search across GitHub

USAGE:
    gh-fzf search <type> [query]

SEARCH TYPES:
    repos       Search repositories
    issues      Search issues
    prs         Search pull requests

EXAMPLES:
    gh-fzf search repos              # Interactive repository search
    gh-fzf search issues "bug"       # Search issues with initial query
    gh-fzf search prs "fix"          # Search pull requests

KEYBOARD SHORTCUTS:
    ctrl-o      Open in web browser
    ctrl-r      Reload search results
    alt-g       Clone repo (repos only)
    alt-c       Comment on issue or PR
    alt-enter   View details in terminal
    ESC         Exit
EOF
		return 0
	fi

	case "$search_type" in
	repos | repositories)
		_gh_search_repos_list "$@"
		;;
	issues)
		_gh_search_issues_list "$@"
		;;
	prs | pull-requests)
		_gh_search_prs_list "$@"
		;;
	"")
		gum log --level error "Search type required"
		gum log --level info "Available types: repos, issues, prs"
		gum log --level info "Run 'gh fzf search --help' for detailed usage information"
		return 1
		;;
	*)
		gum log --level error "Unknown search type '$search_type'"
		gum log --level info "Available types: repos, issues, prs"
		gum log --level info "Run 'gh fzf search --help' for detailed usage information"
		return 1
		;;
	esac
}
