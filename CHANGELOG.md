# Changelog

## [0.9.1](https://github.com/gh-extensions/gh-fzf/compare/v0.9.0...v0.9.1) (2026-03-19)


### Bug Fixes

* quote tmux title in execute-silent bindings to prevent word-splitting ([d42c05a](https://github.com/gh-extensions/gh-fzf/commit/d42c05ab8e9e43d47e13e1aff396fcbc4b9505f9))

## [0.9.0](https://github.com/gh-extensions/gh-fzf/compare/v0.8.0...v0.9.0) (2026-03-08)


### Features

* add clone/fork path configuration via env vars and git config ([0a9301f](https://github.com/gh-extensions/gh-fzf/commit/0a9301f40d04ed9bfd548b73bab0d0e96f1c35c8))


### Bug Fixes

* improve fzf keybinding mnemonics ([91f7253](https://github.com/gh-extensions/gh-fzf/commit/91f7253d9c898a0d0b49b76e117b22a988d1c92f))
* rebind pr view details from alt-enter/alt-v(checks) to alt-v ([31910f2](https://github.com/gh-extensions/gh-fzf/commit/31910f26befefdc3f370b5023576bd19d0d5bf9f))
* rebind repo view from alt-enter to alt-v ([16d597c](https://github.com/gh-extensions/gh-fzf/commit/16d597cb67a9c887eac25196dc2f179ccaaa9dc3))
* rebind view details from alt-enter to alt-v for issue, run, search ([e916502](https://github.com/gh-extensions/gh-fzf/commit/e9165020d5c73c6e5476a7233ad6a3ee74c8a057))

## [0.8.0](https://github.com/gh-extensions/gh-fzf/compare/v0.7.0...v0.8.0) (2026-03-08)


### Features

* add tmux display-popup support for terminal bindings ([bade230](https://github.com/gh-extensions/gh-fzf/commit/bade2302d2d54b6f9666ed877d5ef9e60f1f1880))


### Bug Fixes

* parse GH_FZF_*_OPTS like FZF_DEFAULT_OPTS using eval ([ac02c71](https://github.com/gh-extensions/gh-fzf/commit/ac02c71a8fb64237c9a04fc89344148431a3ec90))
* rename `command` to `cmd` in main() to avoid shadowing bash builtin ([32cc213](https://github.com/gh-extensions/gh-fzf/commit/32cc21385aaeab2e09877d8592f0b85667f01275))
* replace eval array parsing with xargs to handle unquoted parentheses ([e03fed9](https://github.com/gh-extensions/gh-fzf/commit/e03fed912e73b6fdd4fd2417162cb166ad69782c))
* use execute instead of execute-silent for alt-e (gh pr edit) ([25b4e4b](https://github.com/gh-extensions/gh-fzf/commit/25b4e4be7449adef68f655250e1c776e006ca2dd))

## [0.7.0](https://github.com/gh-extensions/gh-fzf/compare/v0.6.0...v0.7.0) (2026-03-07)


### Features

* add status feedback to fzf keybindings ([aa49cee](https://github.com/gh-extensions/gh-fzf/commit/aa49cee8b5b30045243b8df6cc90f9c9d7729a3d))
* force ANSI color output in gh_core script ([252a00c](https://github.com/gh-extensions/gh-fzf/commit/252a00c426afc8eb76a95c685d9a30275ffddb56))

## [0.6.0](https://github.com/gh-extensions/gh-fzf/compare/v0.5.0...v0.6.0) (2026-03-06)


### Features

* add change-footer feedback to ctrl-r reload bindings ([7ddb3e3](https://github.com/gh-extensions/gh-fzf/commit/7ddb3e3b3b546bc1f38e37d90ea1c28711d29cc8))
* replace Keyboard Shortcuts heading with preview-label border title ([a8ad0a4](https://github.com/gh-extensions/gh-fzf/commit/a8ad0a4aa7d6aaa48682315078e282c399707513))
* use preview-label for help panel instead of markdown heading ([ddeb15e](https://github.com/gh-extensions/gh-fzf/commit/ddeb15ef7a4dfe2f804a49904591dbf1d25b639b))

## [0.5.0](https://github.com/gh-extensions/gh-fzf/compare/v0.4.0...v0.5.0) (2026-02-27)


### Features

* add request changes AI shortcut (alt-N) to PR reviews ([66f466e](https://github.com/gh-extensions/gh-fzf/commit/66f466ecc958d5ae0c49109a6026ba0ff342ded9))


### Bug Fixes

* reorder AI PR review keybindings for consistency ([6e57310](https://github.com/gh-extensions/gh-fzf/commit/6e573102d977911f325b0556731f6d6392941cec))

## [0.4.0](https://github.com/gh-extensions/gh-fzf/compare/v0.3.0...v0.4.0) (2026-02-27)


### Features

* add AI plan issue keybinding to gh_issue script ([91bb669](https://github.com/gh-extensions/gh-fzf/commit/91bb669c95c72af0a765ae47268d619f86f2721c))
* add gh-claude integration with conditional keybindings ([954ccc2](https://github.com/gh-extensions/gh-fzf/commit/954ccc2a4175a965efc7ccc3341ada7f19d89b9d))


### Bug Fixes

* add gum format to ai run explain output pipeline ([377a0c4](https://github.com/gh-extensions/gh-fzf/commit/377a0c4605990c44c80f091f639100df55ffe917))
* correct PR search query, search error propagation, and arg parsing ([1d46c71](https://github.com/gh-extensions/gh-fzf/commit/1d46c711e7a01a41a5470ee9f2c64cb00da28f36))
* handle empty fzf flags array when exporting ([b02b020](https://github.com/gh-extensions/gh-fzf/commit/b02b0202d82a9e6c2f0e4609670f5829d4400e7e))
* parse per-command fzf opts with eval to support quoted bind values ([4acf40c](https://github.com/gh-extensions/gh-fzf/commit/4acf40ccfab8f839788940feed91aae2e915af31))
* polish remaining tech debt items ([4809167](https://github.com/gh-extensions/gh-fzf/commit/4809167f74b95a9f432ccfc619e03aab3d91c6c4))
* remove unused AI develop issue keybinding ([f997f0f](https://github.com/gh-extensions/gh-fzf/commit/f997f0f6c43616c48e7e0744155a3356612794aa))
* replace read builtin with eval for fzf flags parsing ([2b2115c](https://github.com/gh-extensions/gh-fzf/commit/2b2115c8819c47ac9d31a28adea4667b423e6e6d))
* update config key from fzf.clone_base to gh-fzf.clone_base ([321dae0](https://github.com/gh-extensions/gh-fzf/commit/321dae0df665ed001d16d21903845f1035ea3264))
* update run logs viewing to use gum pager ([c56a63c](https://github.com/gh-extensions/gh-fzf/commit/c56a63c2c183aedbf59d28aff32c6331dc5f2a0e))
* use parameter expansion for TMUX variable check ([cb97a0b](https://github.com/gh-extensions/gh-fzf/commit/cb97a0bfd2ddc55a91dad1f11840a5e289d89685))

## [0.3.0](https://github.com/gh-extensions/gh-fzf/compare/v0.2.0...v0.3.0) (2026-02-24)


### Features

* **fzf:** add tmux-aware fzf execute action ([4623628](https://github.com/gh-extensions/gh-fzf/commit/4623628c384edc09a3fc54bf4f1e3129c145eda5))


### Bug Fixes

* use execute-silent for view commands in fzf bindings ([458eefb](https://github.com/gh-extensions/gh-fzf/commit/458eefb5b88cadf8dd48b737d50e1c1d761b2da8))

## [0.2.0](https://github.com/gh-extensions/gh-fzf/compare/v0.1.0...v0.2.0) (2026-02-22)


### Features

* add interactive fuzzy finder for GitHub CLI ([0b2a59d](https://github.com/gh-extensions/gh-fzf/commit/0b2a59de7e03da9d0c356802af8d36e933e74d3a))
* add more keybindings to gh-fzf ([4f4d708](https://github.com/gh-extensions/gh-fzf/commit/4f4d708753f3ff7daf20b746b589edad470465a8))
* **cli:** add custom repository clone directory support ([36c6114](https://github.com/gh-extensions/gh-fzf/commit/36c6114888d08f7bd8fe9ae53325f6e2b924d589))
* **cli:** add custom repository clone directory support for forking ([bcaa3b3](https://github.com/gh-extensions/gh-fzf/commit/bcaa3b3f641bda3115b59f81e4c0028390c22a8b))
* **cli:** add fzf configuration and icon for gh commands ([f939f01](https://github.com/gh-extensions/gh-fzf/commit/f939f01b6f91df615b5234d941cd23d682fd8c86))
* **cli:** add global fzf flags support for gh-fzf extension ([1d9e311](https://github.com/gh-extensions/gh-fzf/commit/1d9e311f4ccecadb91a0e99b0c676b6afd75122a))
* **cli:** add per-command fzf configuration via environment variables ([54ccc37](https://github.com/gh-extensions/gh-fzf/commit/54ccc378600b072e4bfd601335a9c7d00372c96f))
* **cli:** consolidate fzf configuration and script sourcing ([261c2e2](https://github.com/gh-extensions/gh-fzf/commit/261c2e29cbffd16571e9d01d2371322e665cd390))
* **cli:** display repository name in extension footers ([c978822](https://github.com/gh-extensions/gh-fzf/commit/c978822f7743cacc5aaa7408add3cada93a10c2b))
* **cli:** display repository name in extension footers ([54c5649](https://github.com/gh-extensions/gh-fzf/commit/54c564943893c1e3923ccc497cdd5fbae25267f0))
* **cli:** improve global fzf flags handling ([33c6158](https://github.com/gh-extensions/gh-fzf/commit/33c61587d46bad9bf93e7af8eecfabfa8f21cecb))
* **gh-cli:** add help preview and toggle functionality to various list views ([ab4946c](https://github.com/gh-extensions/gh-fzf/commit/ab4946c647256fd5dabcb0f5bdf05567a462dcbf))
* **gh-issue:** reload list after editing issue ([e0d81e7](https://github.com/gh-extensions/gh-fzf/commit/e0d81e72fc5f1c0266944969318fc1849df568a3))
* implement interactive issue browsing with gh-fzf ([4ba608d](https://github.com/gh-extensions/gh-fzf/commit/4ba608d0c2fbb8313f228afe636f4cb91c64575a))
* implement interactive pull request browsing ([3c31b48](https://github.com/gh-extensions/gh-fzf/commit/3c31b489da3aad95775a6d1f6a55d0aad78ae88e))
* implement interactive workflow runs ([f417af8](https://github.com/gh-extensions/gh-fzf/commit/f417af8c1469d21db28f13e49a5c6e71a89e70ee))
* **issue:** add interactive label selection ([da5508a](https://github.com/gh-extensions/gh-fzf/commit/da5508a3b928d50522442a29d3ad8cf9941deddb))
* **search:** add interactive GitHub search across repositories, issues, and PRs ([edf30d2](https://github.com/gh-extensions/gh-fzf/commit/edf30d2783f408f025d694a11c810977dc005ec4))
* use enter to view selected resource ([f9bf870](https://github.com/gh-extensions/gh-fzf/commit/f9bf87048012cd18dd3a1a076dc2cb22c3ba07c7))


### Bug Fixes

* add validation for required dependencies and parameters ([3a410c6](https://github.com/gh-extensions/gh-fzf/commit/3a410c6f0e2714f987128ebb45dadb95d6a99907))
* **cli:** update issue template path ([aeef656](https://github.com/gh-extensions/gh-fzf/commit/aeef6565c1dd83766bb7c4f0a22ed169d1661764))
* **scripts:** expand tilde in clone base paths ([bd6f43c](https://github.com/gh-extensions/gh-fzf/commit/bd6f43c972d03173ee310b73eb65f4189c6d2adc))
* **search:** use gh_repo_cmd.sh for consistent clone behavior ([c63d199](https://github.com/gh-extensions/gh-fzf/commit/c63d1992da1f2c1ca3105d0924874c47dacecb23))
