# Configuration

## Clone base directory

By default `alt-g` (clone) and `alt-f` (fork) clone into the current directory.
Set a base directory to have gh-fzf organise clones automatically:

```bash
gh config set gh-fzf.clone_base ~/Projects
```

With this set, cloning `owner/repo` places it at `~/Projects/github.com/owner/repo`.
Parent directories are created automatically. Tilde (`~`) is expanded to `$HOME`.

## Custom fzf options

Each view can be tuned with environment variables. Per-command variables take
precedence over the global one.

| Variable | Scope |
|----------|-------|
| `GH_FZF_FLAGS` | Applied to all views |
| `GH_FZF_REPO_OPTS` | Repositories only |
| `GH_FZF_ISSUE_OPTS` | Issues only |
| `GH_FZF_PR_OPTS` | Pull requests only |
| `GH_FZF_RUN_OPTS` | Workflow runs only |
| `GH_FZF_SEARCH_REPO_OPTS` | Repository search only |
| `GH_FZF_SEARCH_ISSUE_OPTS` | Issue search only |
| `GH_FZF_SEARCH_PR_OPTS` | Pull request search only |

```bash
export GH_FZF_PR_OPTS="--height 90% --border rounded"
export GH_FZF_ISSUE_OPTS="--height 50%"
```

## gh-ai integration

Enable AI-powered shortcuts (explain, review, develop) across PR, issue, and run views:

```bash
gh config set gh-fzf.ai enabled
```

Requires the [gh-ai](https://github.com/gh-extensions/gh-ai) extension to be installed.
When enabled, an **AI Shortcuts** section appears in each view's `alt-h` help panel.

## Debug mode

```bash
DEBUG=1 gh fzf pr
```
