# Pull Requests

Browse and manage GitHub pull requests interactively.

## Usage

```bash
gh fzf pr
gh fzf pr --state closed
gh fzf pr --author @me
gh fzf pr --label bug
gh fzf pr --search "query"
gh fzf pr --limit 50
```

Pass `--help` to see all available flags from the GitHub CLI:

```bash
gh fzf pr --help
```

## Keyboard shortcuts

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

## AI shortcuts

> Requires `gh config set gh-fzf.ai enabled` and the [gh-ai](https://github.com/gh-extensions/gh-ai) extension.

| Key | Action |
|-----|--------|
| `alt-E` | Explain PR |
| `alt-R` | Review PR |
