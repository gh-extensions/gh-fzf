# Contributing

## Getting started

1. Fork and clone the repository.
2. Make your changes in a feature branch.
3. Test manually by running the scripts directly:

```bash
# Run a command with debug output
DEBUG=1 ./gh-fzf issue

# Test a subcommand directly
DEBUG=1 ./scripts/gh_issue_cmd.sh add-label 42
DEBUG=1 ./scripts/gh_repo_cmd.sh clone owner/repo
```

4. Open a pull request against `main`.

## Project structure

```
gh-fzf                      # main entry point
scripts/
  gh_core.sh                # shared utilities (fzf options, repo detection)
  gh_issue.sh               # issue fzf view
  gh_issue_cmd.sh           # issue subcommands (list, add-label, help)
  gh_pr.sh                  # PR fzf view
  gh_pr_cmd.sh              # PR subcommands
  gh_repo.sh                # repo fzf view
  gh_repo_cmd.sh            # repo subcommands (list, clone, fork, help)
  gh_run.sh                 # run fzf view
  gh_run_cmd.sh             # run subcommands
  gh_search.sh              # search fzf views
  gh_search_cmd.sh          # search subcommands
templates/
  gh_issue_list.tmpl        # go template for issue list output
  gh_pr_list.tmpl           # go template for PR list output
  gh_repo_list.tmpl         # go template for repo list output
  gh_run_list.tmpl          # go template for run list output
  gh_search_*.tmpl          # go templates for search output
```

Each command follows the same pattern: a `gh_<cmd>.sh` file sets up the fzf
view and bindings, and a `gh_<cmd>_cmd.sh` file provides the subcommands
invoked by those bindings (and can be run directly for testing).
