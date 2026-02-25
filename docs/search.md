# Search

Search across all of GitHub. Results update live as you type.

## Usage

```bash
gh fzf search repos              # interactive repository search
gh fzf search issues             # interactive issue search
gh fzf search prs                # interactive pull request search
gh fzf search repos "cli"        # start with an initial query
```

## Keyboard shortcuts

### Repositories

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-g` | Clone repository |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

### Issues

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-c` | Comment on issue |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

### Pull Requests

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in web browser |
| `ctrl-r` | Reload results |
| `alt-c` | Comment on PR |
| `alt-enter` | View details in terminal |
| `alt-h` | Toggle help |

## AI shortcuts

> Requires `gh config set gh-fzf.ai enabled` and the [gh-ai](https://github.com/gh-extensions/gh-ai) extension.

| Key | Action |
|-----|--------|
| `alt-E` | Explain PR |
| `alt-R` | Review PR |
