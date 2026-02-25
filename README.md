# gh-fzf

A GitHub CLI extension that provides an interactive fuzzy finder for browsing
and managing repositories, issues, pull requests, workflow runs, and GitHub
search — all from the terminal.

![License](https://img.shields.io/github/license/gh-extensions/gh-fzf)
![Version](https://img.shields.io/github/v/release/gh-extensions/gh-fzf)

## Prerequisites

- [Gum](https://github.com/charmbracelet/gum) (`gum`) — macOS: `brew install gum`
- [Bash](https://www.gnu.org/software/bash/) 4.4+ (`bash`) — macOS: `brew install bash`
- [GitHub CLI](https://cli.github.com/) (`gh`) — macOS: `brew install gh`
- [Fzf](https://github.com/junegunn/fzf) (`fzf`) — macOS: `brew install fzf`

## Installation

```bash
gh extension install gh-extensions/gh-fzf
```

## Usage

```bash
gh fzf repo      # browse your repositories
gh fzf issue     # browse issues in the current repo
gh fzf pr        # browse pull requests in the current repo
gh fzf run       # browse workflow runs in the current repo
gh fzf search repos "cli"   # search across all of GitHub
```

In every view, press `alt-h` to toggle the keyboard shortcut reference.

## Documentation

| Topic                                |                                             |
| ------------------------------------ | ------------------------------------------- |
| [Repositories](docs/repos.md)        | Browse, clone, and fork repositories        |
| [Issues](docs/issues.md)             | Browse, comment, label, and manage issues   |
| [Pull Requests](docs/prs.md)         | Review, approve, merge, and manage PRs      |
| [Workflow Runs](docs/runs.md)        | Monitor, rerun, and download run artifacts  |
| [Search](docs/search.md)             | Search repos, issues, and PRs across GitHub |
| [Configuration](docs/config.md)      | Clone base path, fzf options, debug mode    |
| [Contributing](docs/contributing.md) | Project structure and development guide     |

## License

[MIT](LICENSE) — Copyright (c) 2025 gh-extensions

<!-- markdownlint-disable-file MD013 -->
