# gh_repo.sh - GitHub Repository commands for gh-fzf
#
# This file is sourced by the main gh-fzf script and provides
# repository listing and interactive functionality.
#
# Dependencies from main gh-fzf:
#   - $_gh_fzf_source_dir (source directory path)
#   - _gh_filter_list_args() (argument filtering function)

# _gh_repo_list()
#
# Interactive fuzzy finder for GitHub repositories
#
# DESCRIPTION:
#   Displays a list of GitHub repositories in an interactive fuzzy finder (fzf)
#   with various keyboard shortcuts for common repository operations. Shows up to 30
#   most recent repositories with detailed information including name, description,
#   stars, primary language, visibility, and last update time.
#
# PARAMETERS:
#   $@ - Optional owner and flags to pass to gh repo list (e.g., octocat, --language Go,
#        --visibility public, --limit 50)
#        Flags controlled by gh-fzf (--json, --jq, --template) are filtered out
#
# RETURNS:
#   0 - Success (user performed an action or exited normally)
#   1 - Failure (no repositories found or not authenticated)
#
# KEYBOARD SHORTCUTS:
#   enter    - View repository details in terminal
#   ctrl-o   - Open repository in web browser
#   alt-c    - Clone repository
#   alt-f    - Fork repository
#   alt-v    - View repository README
#
# DEPENDENCIES:
#   - gh (GitHub CLI)
#   - fzf (fuzzy finder)
#   - gum (for spinner and logging)
#
# NOTES:
#   - Repository name is extracted from the first column in fzf selections
#   - Repositories are sorted by update time (most recent first)
#   - Supports optional [owner] argument: gh fzf repo <owner>
#
# EXAMPLE:
#   gh-fzf repo
#   gh-fzf repo octocat
#   gh-fzf repo --language Go
#
_gh_repo_list() {
	# Show help if requested
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		gh repo list --help
		return $?
	fi

	# Filter out arguments that gh-fzf controls
	local _gh_fzf_filtered_args=$(_gh_filter_list_args "$@")

	# Set up columns and template
	local repo_columns="nameWithOwner,description,stargazerCount,primaryLanguage,visibility,isArchived,pushedAt"
	local repo_template
	local repo_list

	repo_template=$(cat "$_gh_fzf_source_dir/templates/gh_repo_list.tmpl")

	# Query GitHub for repositories with spinner feedback
	repo_list=$(gum spin --title "Loading GitHub Repositories..." -- \
		gh repo list $_gh_fzf_filtered_args --json "$repo_columns" --template "$repo_template")

	# Check if we got any repositories
	if [ -z "$repo_list" ]; then
		gum log --level warn "No GitHub Repositories found. Make sure you're authenticated with GitHub CLI."
		return 1
	fi

	# Transform and present in fzf
	echo "$repo_list" | fzf --ansi \
		--with-nth 1.. \
		--accept-nth 1 \
		--header "  GitHub Repositories" \
		--header-lines 1 \
		--color header:blue \
		--bind "enter:execute(gh repo view {1})+abort" \
		--bind "ctrl-o:execute-silent(gh repo view {1} --web)" \
		--bind "alt-c:execute($_gh_fzf_source_dir/scripts/gh_clone_to_project.sh {1})+abort" \
		--bind "alt-f:execute(gh repo fork {1})+abort" \
		--bind "alt-v:execute(gh repo view {1} --readme)+abort"
}
