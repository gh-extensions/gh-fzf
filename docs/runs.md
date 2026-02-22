# Workflow Runs

Browse and manage GitHub Actions workflow runs interactively.

## Usage

```bash
gh fzf run
gh fzf run --status success
gh fzf run --branch main
gh fzf run --workflow "CI"
gh fzf run --limit 50
```

Pass `--help` to see all available flags from the GitHub CLI:

```bash
gh fzf run --help
```

## Keyboard shortcuts

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
