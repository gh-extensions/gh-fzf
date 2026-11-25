#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_gh_repo_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_repo_cmd_source_dir/gh_core.sh"

# gh_repo_cmd.sh - Repository command wrapper for gh-fzf
#
# Provides clone and fork functionality, primarily for use with fzf bindings.
# Handles optional cloning into base directories configured via GH_FZF_REPO_PATH
# or `gh config set fzf.repoPath <path>`.
#
# SUBCOMMANDS:
#   clone [repo] - Clones the specified repository.
#   fork [repo]  - Forks and clones the specified repository.
#
# CONFIGURATION:
#   - GH_FZF_REPO_PATH: Optional base directory for clone and fork (env var, takes precedence).
#     Example: export GH_FZF_REPO_PATH=~/Projects
#   - fzf.repoPath: Optional base directory for clone and fork (gh config fallback).
#     Example: gh config set fzf.repoPath ~/Projects
#
# DIRECT EXECUTION:
#   When run directly, dispatches to the specified subcommand.
#   Example: ./gh_repo_cmd.sh clone owner/repo

# _gh_config_repo_path()
#
# Resolves the base directory for clone and fork operations.
# Checks GH_FZF_REPO_PATH env var first, then fzf.repoPath gh config.
# Expands tilde to $HOME.
#
_gh_config_repo_path() {
	local repo_path="${GH_FZF_REPO_PATH:-}"
	if [[ -z "$repo_path" ]]; then
		repo_path=$(gh config get fzf.repoPath 2>/dev/null)
	fi
	# Expand tilde to home directory
	printf '%s' "${repo_path/#\~/$HOME}"
}

# _gh_repo_clone()
#
# Clones a GitHub repository, respecting GH_FZF_REPO_PATH or fzf.repoPath if set.
#
# DESCRIPTION:
#   Clones the specified repository using `gh repo clone`. If a repo path is
#   configured, it constructs a destination of `$base/github.com/owner/repo`.
#   Otherwise, it clones into the current directory.
#
# PARAMETERS:
#   $1 - The repository to clone (e.g., "owner/repo").
#
# EXAMPLE:
#   _gh_repo_clone "owner/repo"
#   # With GH_FZF_REPO_PATH=~/Projects -> gh repo clone owner/repo ~/Projects/github.com/owner/repo
#
#   _gh_repo_clone "owner/repo"
#   # Without repoPath configured -> gh repo clone owner/repo
#
_gh_repo_clone() {
	local repo="$1"
	local repo_path
	repo_path=$(_gh_config_repo_path)

	if [ -n "$repo_path" ]; then
		local clone_dir="$repo_path/github.com/$repo"
		mkdir -p "$(dirname "$clone_dir")"
		# process substitution to show spinner while cloning
		gum spin --title "Cloning $repo to $clone_dir..." -- \
			gh repo clone "$repo" "$clone_dir"
	else
		gum spin --title "Cloning $repo..." -- \
			gh repo clone "$repo"
	fi
}

# _gh_repo_fork()
#
# Forks a GitHub repository and clones it, respecting GH_FZF_REPO_PATH or fzf.repoPath.
#
# DESCRIPTION:
#   Forks the specified repository using `gh repo fork --clone`.
#   If a repo path is configured, it forks AND clones to a destination of
#   `$base/github.com/your-username/repo`. Otherwise, clones to the current directory.
#
# PARAMETERS:
#   $1 - The repository to fork (e.g., "owner/repo").
#
# EXAMPLE:
#   _gh_repo_fork "owner/repo"
#   # With GH_FZF_REPO_PATH=~/Projects -> gh repo fork owner/repo --clone --fork-name ...
#
_gh_repo_fork() {
	local repo="$1"
	local owner
	owner=$(gh api user -q '.login' 2>/dev/null || true)
	if [[ -z "$owner" ]]; then
		gum log --level error "Failed to detect GitHub username"
		return 1
	fi

	local fork_name
	fork_name=$(basename "$repo")
	local repo_path
	repo_path=$(_gh_config_repo_path)

	if [ -n "$repo_path" ]; then
		local fork_dir="$repo_path/github.com/$owner/$fork_name"
		mkdir -p "$(dirname "$fork_dir")"
		# Fork without cloning, then clone to the target directory
		gum spin --title "Forking $repo..." -- \
			gh repo fork "$repo" --clone=false --fork-name "$fork_name"
		gum spin --title "Cloning $owner/$fork_name to $fork_dir..." -- \
			gh repo clone "$owner/$fork_name" "$fork_dir"
	else
		gum spin --title "Forking and cloning $repo..." --show-stderr -- \
			gh repo fork "$repo" --clone
	fi
}

# _gh_repo_list_cmd()
#
# List GitHub repositories
#
# DESCRIPTION:
#   Fetches a list of GitHub repositories with detailed information.
#
# PARAMETERS:
#   $@ - Optional flags to pass to gh repo list
#
# RETURNS:
#   A formatted string of repositories, one per line.
#
_gh_repo_list_cmd() {
	local -a _gh_fzf_filtered_args=()
	_gh_parse_list_args _gh_fzf_filtered_args "$@"

	# Set up columns and template
	local repo_columns="nameWithOwner,description,stargazerCount,primaryLanguage,visibility,isArchived,pushedAt"
	local repo_template

	repo_template=$(cat "$_gh_repo_cmd_source_dir/../templates/gh_repo_list.tmpl")

	# Query GitHub for repositories with spinner feedback
	gum spin --title "Loading GitHub Repositories..." -- \
		gh repo list "${_gh_fzf_filtered_args[@]}" --json "$repo_columns" --template "$repo_template"
}

# _gh_repo_preview_help()
#
# Display keyboard shortcuts for repository list
#
# DESCRIPTION:
#   Outputs formatted help text showing available keyboard shortcuts
#   for the repository list. Designed to be displayed in fzf preview window.
#
# RETURNS:
#   Formatted help text with shortcuts and tips
#
_gh_repo_preview_help() {
	gum format <<'EOF'
| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open in web browser |
| **`ctrl-r`** | Reload list |
| **`alt-c`** | Clone repository |
| **`alt-f`** | Fork and clone |
| **`alt-v`** | View details |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit |
EOF
}

# Main dispatcher for direct execution
main() {
	local subcommand="${1:-}"
	# Execute the appropriate function based on the subcommand
	case "$subcommand" in
	clone)
		shift
		_gh_repo_clone "$@"
		;;
	fork)
		shift
		_gh_repo_fork "$@"
		;;
	list)
		shift
		_gh_repo_list_cmd "$@"
		;;
	preview-help)
		_gh_repo_preview_help
		;;
	*)
		echo "Usage: $0 {clone|fork|list|preview-help} [repo]"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
