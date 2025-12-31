#!/bin/bash
# gh_fork_to_project.sh - Custom fork directory wrapper for gh-fzf
#
# This script wraps `gh repo fork` to support custom fork directories
# configured via `gh config set fzf.clone_base <path>`.
#
# Usage: gh_fork_to_project.sh <owner/repo>
#
# Configuration:
#   gh config set fzf.clone_base ~/Projects
#
# Behavior:
#   - If fzf.clone_base is set: Fork AND clone to $base/github.com/your-username/repo
#   - If not set: Fork only (default gh behavior, no clone)
#
# Examples:
#   # With config: gh config set fzf.clone_base ~/Projects
#   gh_fork_to_project.sh cli/cli
#   # Forks to: github.com/YOUR-USERNAME/cli
#   # Clones to: ~/Projects/github.com/YOUR-USERNAME/cli
#
#   # Without config:
#   gh_fork_to_project.sh cli/cli
#   # Forks to: github.com/YOUR-USERNAME/cli (no clone)

# Accept repository name in owner/repo format
repo="$1"

# Validate argument
if [ -z "$repo" ]; then
	echo "Error: Repository name required (e.g., owner/repo)" >&2
	exit 1
fi

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
