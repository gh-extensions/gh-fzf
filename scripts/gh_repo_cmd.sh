#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

_gh_repo_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=gh_core.sh
source "$_gh_repo_cmd_source_dir/gh_core.sh"

# gh_repo_cmd.sh - Repository command wrapper for gh-fzf
#
# Provides clone and fork functionality, primarily for use with fzf bindings.
# Handles optional cloning into base directories configured via `gh config set fzf.clone_base <path>`.
#
# SUBCOMMANDS:
#   clone [repo] - Clones the specified repository.
#   fork [repo]  - Forks and clones the specified repository.
#
# CONFIGURATION:
#   - fzf.clone_base: Optional base directory for cloning.
#     Example: gh config set fzf.clone_base ~/Projects
#
# DIRECT EXECUTION:
#   When run directly, dispatches to the specified subcommand.
#   Example: ./gh_repo_cmd.sh clone owner/repo

# _gh_repo_clone()
#
# Clones a GitHub repository, respecting fzf.clone_base if set.
#
# DESCRIPTION:
#   Clones the specified repository using `gh repo clone`. If `fzf.clone_base`
#   is configured in gh settings, it constructs a destination path of
#   `$base/github.com/owner/repo`. Otherwise, it clones into the current directory.
#
# PARAMETERS:
#   $1 - The repository to clone (e.g., "owner/repo").
#
# BEHAVIOR:
#   - Reads `fzf.clone_base` from gh config.
#   - If fzf.clone_base is configured, clones to $base/github.com/owner/repo.
#   - If not, clones to the current directory.
#
# EXAMPLE:
#   _gh_repo_clone "owner/repo"
#   # With fzf.clone_base = ~/Projects -> gh repo clone owner/repo ~/Projects/github.com/owner/repo
#
#   _gh_repo_clone "owner/repo"
#   # Without fzf.clone_base -> gh repo clone owner/repo
#
_gh_repo_clone() {
	local repo="$1"
	local clone_base
	clone_base=$(gh config get fzf.clone_base 2>/dev/null)

	if [ -n "$clone_base" ]; then
		local clone_dir="$clone_base/github.com/$repo"
		mkdir -p "$(dirname "$clone_dir")"
		gum log --level info "Cloning $repo to $clone_dir..."
		gh repo clone "$repo" "$clone_dir"
	else
		gum log --level info "Cloning $repo..."
		gh repo clone "$repo"
	fi
}

# _gh_repo_fork()
#
# Forks a GitHub repository and clones it, respecting fzf.clone_base.
#
# DESCRIPTION:
#   Forks the specified repository using `gh repo fork --clone`.
#   If fzf.clone_base is configured, it forks AND clones to a destination path of
#   `$base/github.com/your-username/repo`. Otherwise, it clones to the current directory.
#
# PARAMETERS:
#   $1 - The repository to fork (e.g., "owner/repo").
#
# BEHAVIOR:
#   - Reads `fzf.clone_base` from gh config.
#   - Forks the repository with the `--clone` flag.
#   - If fzf.clone_base is set: Fork AND clone to $base/github.com/your-username/repo
#   - If not, fork and clone to the current directory.
#
# EXAMPLE:
#   _gh_repo_fork "owner/repo"
#   # With fzf.clone_base = ~/Projects -> gh repo fork owner/repo --clone --fork-name ...
#
_gh_repo_fork() {
	local repo="$1"
	local owner
	owner=$(gh config get user)
	local fork_name
	fork_name=$(basename "$repo")
	local clone_base
	clone_base=$(gh config get fzf.clone_base 2>/dev/null)

	if [ -n "$clone_base" ]; then
		local clone_dir="$clone_base/github.com/$owner/$fork_name"
		mkdir -p "$(dirname "$clone_dir")"
		gum log --level info "Forking and cloning $repo to $clone_dir..."
		gh repo fork "$repo" --clone --fork-name "$fork_name"
		# Move the cloned repo to the correct directory
		mv "$fork_name" "$clone_dir"
	else
		gum log --level info "Forking and cloning $repo..."
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
    local _gh_fzf_filtered_args
    # Filter out arguments that gh-fzf controls
    _gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

    # Set up columns and template
    local repo_columns="nameWithOwner,description,stargazerCount,primaryLanguage,visibility,isArchived,pushedAt"
    local repo_template

    repo_template=$(cat "$_gh_repo_cmd_source_dir/../templates/gh_repo_list.tmpl")

    # Query GitHub for repositories with spinner feedback
    # shellcheck disable=SC2086
    gum spin --title "Loading GitHub Repositories..." -- \
        gh repo list $_gh_fzf_filtered_args --json "$repo_columns" --template "$repo_template"
}


# Main dispatcher for direct execution
main() {
	local subcommand="$1"
	shift
	case "$subcommand" in
	clone)
		_gh_repo_clone "$@"
		;;
	fork)
		_gh_repo_fork "$@"
		;;
	list)
		_gh_repo_list_cmd "$@"
		;;
	*)
		echo "Usage: $0 {clone|fork|list} [repo]"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
