#!/bin/bash
# gh_clone_to_project.sh - Custom clone directory wrapper for gh-fzf
#
# This script wraps `gh repo clone` to support custom clone directories
# configured via `gh config set fzf.clone_base <path>`.
#
# Usage: gh_clone_to_project.sh <owner/repo>
#
# Configuration:
#   gh config set fzf.clone_base ~/Projects
#
# Behavior:
#   - If fzf.clone_base is set: Clone to $base/github.com/owner/repo
#   - If not set: Clone to current directory (default gh behavior)
#
# Examples:
#   # With config: gh config set fzf.clone_base ~/Projects
#   gh_clone_to_project.sh cli/cli
#   # Clones to: ~/Projects/github.com/cli/cli
#
#   # Without config:
#   gh_clone_to_project.sh cli/cli
#   # Clones to: ./cli (current directory)

# Accept repository name in owner/repo format
repo="$1"

# Validate argument
if [ -z "$repo" ]; then
	echo "Error: Repository name required (e.g., owner/repo)" >&2
	exit 1
fi

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
