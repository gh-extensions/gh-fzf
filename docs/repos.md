# Repositories

Browse and manage GitHub repositories interactively.

## Usage

```bash
gh fzf repo              # your repositories
gh fzf repo octocat      # another user's repositories
gh fzf repo --language Go
gh fzf repo --visibility public
gh fzf repo --limit 50
```

Pass `--help` to see all available flags from the GitHub CLI:

```bash
gh fzf repo --help
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload list |
| `alt-g` | Clone repository |
| `alt-f` | Fork repository |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

> `alt-g` and `alt-f` respect the `gh-fzf.clone_base` config setting.
> See [configuration](config.md) for details.
