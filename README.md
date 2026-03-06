# gh-fzf

Supercharge the GitHub CLI with fuzzy finding. Browse, search, and act on
pull requests, issues, workflow runs, and repositories — instantly, from
your terminal.

No more copy-pasting PR numbers or clicking through the GitHub UI. `gh fzf`
gives you a fast, keyboard-driven interface to everything in your repo.

## Prerequisites

- [Gum](https://github.com/charmbracelet/gum) (`gum`) — macOS: `brew install gum`
- [Bash](https://www.gnu.org/software/bash/) 4.4+ (`bash`) — macOS: `brew install bash`
- [GitHub CLI](https://cli.github.com/) (`gh`) — macOS: `brew install gh`
- [Fzf](https://github.com/junegunn/fzf) (`fzf`) — macOS: `brew install fzf`

## Installation

```bash
gh extension install gh-extensions/gh-fzf --pin v0.6.0  # recommended: pin to a stable release
gh extension install gh-extensions/gh-fzf                # installs from main (unstable)
```

## Usage

```bash
gh fzf pr                   # browse pull requests in the current repo
gh fzf issue                # browse issues in the current repo
gh fzf run                  # browse workflow runs in the current repo
gh fzf repo                 # browse your repositories
gh fzf search repos "cli"   # search across all of GitHub
```

In every view, press `alt-h` to toggle the keyboard shortcut reference.

## Pull Requests

```bash
gh fzf pr
gh fzf pr --state closed
gh fzf pr --author @me
gh fzf pr --label bug
gh fzf pr --search "query"
gh fzf pr --limit 50
```

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload list |
| `ctrl-w` | View checks in web browser |
| `alt-c` | Comment on PR |
| `alt-a` | Approve PR (LGTM) |
| `alt-e` | Edit PR |
| `alt-r` | Mark as ready for review |
| `alt-x` | Close PR |
| `alt-m` | Merge PR (rebase, delete branch) |
| `alt-k` | View checks in terminal |
| `alt-w` | Watch checks in terminal |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

## Issues

```bash
gh fzf issue
gh fzf issue --state closed
gh fzf issue --assignee @me
gh fzf issue --label bug
gh fzf issue --search "query"
gh fzf issue --limit 50
```

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload list |
| `alt-c` | Comment on issue |
| `alt-e` | Edit issue |
| `alt-x` | Close issue |
| `alt-r` | Reopen issue |
| `alt-a` | Assign to me |
| `alt-t` | Add label |
| `alt-p` | Pin issue |
| `alt-u` | Unpin issue |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

## Workflow Runs

```bash
gh fzf run
gh fzf run --status success
gh fzf run --branch main
gh fzf run --workflow "CI"
gh fzf run --limit 50
```

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload list |
| `alt-x` | Cancel run |
| `alt-r` | Rerun workflow |
| `alt-l` | View logs in terminal |
| `alt-d` | Download artifacts |
| `alt-w` | Watch run progress in terminal |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

## Repositories

```bash
gh fzf repo              # your repositories
gh fzf repo octocat      # another user's repositories
gh fzf repo --language Go
gh fzf repo --visibility public
gh fzf repo --limit 50
```

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload list |
| `alt-g` | Clone repository |
| `alt-f` | Fork repository |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

> `alt-g` and `alt-f` respect the `fzf.clone_base` config setting.
> See [Configuration](#configuration) for details.

## Search

Search across all of GitHub. Results update live as you type.

```bash
gh fzf search repos              # interactive repository search
gh fzf search issues             # interactive issue search
gh fzf search prs                # interactive pull request search
gh fzf search repos "cli"        # start with an initial query
```

**Repositories**

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-g` | Clone repository |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

**Issues**

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-c` | Comment on issue |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

**Pull Requests**

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-c` | Comment on PR |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

## Configuration

### Clone base directory

By default `alt-g` (clone) and `alt-f` (fork) clone into the current directory.
Set a base directory to have gh-fzf organise clones automatically:

```bash
gh config set fzf.clone_base ~/Projects
```

With this set, cloning `owner/repo` places it at `~/Projects/github.com/owner/repo`.
Parent directories are created automatically. Tilde (`~`) is expanded to `$HOME`.

### Custom fzf options

Each view can be tuned with environment variables. Per-command variables take
precedence over the global one.

| Variable | Scope |
|----------|-------|
| `GH_FZF_FLAGS` | Applied to all views |
| `GH_FZF_PR_OPTS` | Pull requests only |
| `GH_FZF_ISSUE_OPTS` | Issues only |
| `GH_FZF_RUN_OPTS` | Workflow runs only |
| `GH_FZF_REPO_OPTS` | Repositories only |
| `GH_FZF_SEARCH_REPO_OPTS` | Repository search only |
| `GH_FZF_SEARCH_ISSUE_OPTS` | Issue search only |
| `GH_FZF_SEARCH_PR_OPTS` | Pull request search only |

```bash
export GH_FZF_PR_OPTS="--height 90% --border rounded"
export GH_FZF_ISSUE_OPTS="--height 50%"
```

### Debug mode

```bash
DEBUG=1 gh fzf pr
```

## License

[MIT](LICENSE) — Copyright (c) 2025 gh-extensions

<!-- markdownlint-disable-file MD013 -->
