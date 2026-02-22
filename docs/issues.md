# Issues

Browse and manage GitHub issues interactively.

## Usage

```bash
gh fzf issue
gh fzf issue --state closed
gh fzf issue --assignee @me
gh fzf issue --label bug
gh fzf issue --search "query"
gh fzf issue --limit 50
```

Pass `--help` to see all available flags from the GitHub CLI:

```bash
gh fzf issue --help
```

## Keyboard shortcuts

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
