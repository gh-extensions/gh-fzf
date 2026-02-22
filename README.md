# gh-fzf

Interactive fuzzy finder built with [fzf](https://github.com/junegunn/fzf) for
lightning-fast fuzzy searching GitHub resources and
[gum](https://github.com/charmbracelet/gum) for beautiful terminal UI.

![License](https://img.shields.io/github/license/gh-extensions/gh-fzf)
![Version](https://img.shields.io/github/v/release/gh-extensions/gh-fzf)

## Installation

**Prerequisites:** [gh](https://cli.github.com/) (authenticated), [fzf](https://github.com/junegunn/fzf), [gum](https://github.com/charmbracelet/gum)

```bash
gh extension install gh-extensions/gh-fzf
```

## Quick start

```bash
gh fzf repo      # browse your repositories
gh fzf issue     # browse issues in the current repo
gh fzf pr        # browse pull requests in the current repo
gh fzf run       # browse workflow runs in the current repo
gh fzf search repos "cli"   # search across all of GitHub
```

In every view, press `alt-h` to toggle the keyboard shortcut reference.

## Documentation

| Topic | |
|-------|-|
| [Repositories](docs/repos.md) | Browse, clone, and fork repositories |
| [Issues](docs/issues.md) | Browse, comment, label, and manage issues |
| [Pull Requests](docs/prs.md) | Review, approve, merge, and manage PRs |
| [Workflow Runs](docs/runs.md) | Monitor, rerun, and download run artifacts |
| [Search](docs/search.md) | Search repos, issues, and PRs across GitHub |
| [Configuration](docs/config.md) | Clone base path, fzf options, debug mode |
| [Contributing](docs/contributing.md) | Project structure and development guide |

## License

[MIT](LICENSE) — Copyright (c) 2025 gh-extensions
