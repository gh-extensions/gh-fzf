#!/bin/bash

# gh_repo_cmd.sh - Repository command wrapper for gh-fzf
#
# This script provides clone and fork operations with support for custom
# directories configured via `gh config set fzf.clone_base <path>`.
#
# Usage: gh_repo_cmd.sh <command> <owner/repo>
#
# Commands:
#   clone - Clone a repository to custom directory
#   fork  - Fork and clone a repository to custom directory
#
# Configuration:
#   gh config set fzf.clone_base ~/Projects
#
# Examples:
#   # Clone to custom directory
#   gh_repo_cmd.sh clone cli/cli
#   # With config set: Clones to ~/Projects/github.com/cli/cli
#   # Without config: Clones to ./cli (current directory)
#
#   # Fork and clone to custom directory
#   gh_repo_cmd.sh fork cli/cli
#   # With config set: Forks and clones to ~/Projects/github.com/YOUR-USERNAME/cli
#   # Without config: Forks only (no clone)

# Accept command (clone or fork) and repository
cmd="$1"
repo="$2"

# Validate arguments
if [ -z "$cmd" ]; then
	echo "Error: Command required (clone or fork)" >&2
	exit 1
fi

if [ -z "$repo" ]; then
	echo "Error: Repository name required (e.g., owner/repo)" >&2
	exit 1
fi

# _gh_repo_clone - Clone repository to custom directory
#
# Clones a repository using gh CLI with optional custom directory support.
# If fzf.clone_base is configured, clones to $base/github.com/owner/repo.
# Otherwise uses default gh behavior (current directory).
#
# Arguments:
#   $1 - Repository in owner/repo format
#
# Returns:
#   0 on success, 1 on error
#
# Configuration:
#   gh config set fzf.clone_base ~/Projects
#
# Behavior:
#   - If fzf.clone_base is set: Clone to $base/github.com/owner/repo
#   - If not set: Clone to current directory (default gh behavior)
_gh_repo_clone() {
	local repo="$1"
	local clone_base
	local target_dir

	# Read config (suppress errors if not set)
	clone_base=$(gh config get fzf.clone_base 2>/dev/null)

	# If config not set, use default clone behavior
	if [ -z "$clone_base" ]; then
		exec gh repo clone "$repo"
	fi

	# Expand tilde to home directory
	clone_base="${clone_base/#\~/$HOME}"

	# Construct full clone path
	target_dir="$clone_base/github.com/$repo"

	# Create parent directories
	mkdir -p "$(dirname "$target_dir")" || {
		echo "Error: Cannot create directory $(dirname "$target_dir")" >&2
		exit 1
	}

	# Clone to target directory
	exec gh repo clone "$repo" "$target_dir"
}

# _gh_repo_fork - Fork and clone repository to custom directory
#
# Forks a repository using gh CLI with optional custom directory support.
# If fzf.clone_base is configured, forks AND clones to $base/github.com/your-username/repo.
# Otherwise uses default gh behavior (fork only, no clone).
#
# Arguments:
#   $1 - Repository in owner/repo format
#
# Returns:
#   0 on success, 1 on error
#
# Configuration:
#   gh config set fzf.clone_base ~/Projects
#
# Behavior:
#   - If fzf.clone_base is set: Fork AND clone to $base/github.com/your-username/repo
#   - If not set: Fork only (default gh behavior, no clone)
_gh_repo_fork() {
	local repo="$1"
	local clone_base
	local username
	local repo_name
	local target_dir

	# Read config (suppress errors if not set)
	clone_base=$(gh config get fzf.clone_base 2>/dev/null)

	# If config not set, use default fork behavior (no clone)
	if [ -z "$clone_base" ]; then
		exec gh repo fork "$repo"
	fi

	# Get current GitHub username for fork path
	username=$(gh api user -q .login 2>/dev/null)
	if [ -z "$username" ]; then
		echo "Error: Cannot determine GitHub username" >&2
		exit 1
	fi

	# Extract repo name (without owner)
	repo_name="${repo##*/}"

	# Expand tilde to home directory
	clone_base="${clone_base/#\~/$HOME}"

	# Construct full clone path for the FORK (uses YOUR username)
	target_dir="$clone_base/github.com/$username/$repo_name"

	# Create parent directories
	mkdir -p "$(dirname "$target_dir")" || {
		echo "Error: Cannot create directory $(dirname "$target_dir")" >&2
		exit 1
	}

	# Fork and clone to target directory
	exec gh repo fork "$repo" --clone -- "$target_dir"
}

# Dispatch to appropriate function based on command
case "$cmd" in
clone)
	_gh_repo_clone "$repo"
	;;
fork)
	_gh_repo_fork "$repo"
	;;
*)
	echo "Error: Unknown command '$cmd'. Use 'clone' or 'fork'" >&2
	exit 1
	;;
esac
