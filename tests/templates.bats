#!/usr/bin/env bats

# Regression tests for the gh output templates in templates/
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/templates.bats
#
# gh's `tablerow` template helper truncates every column to the width it detects
# for the terminal, so a narrow terminal cut the repository name in the rows and
# the fzf placeholders (`{1}`, `{2}`, `{-1}`) then cloned or viewed the wrong
# thing. The templates build their rows with `printf` instead, so the fields
# keep their full value whatever the width. See
# https://github.com/gh-extensions/gh-fzf/issues/57

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

@test "templates: no template uses the width-dependent tablerow helper" {
	run grep -l "tablerow" "$REPO_ROOT"/templates/*.tmpl

	[[ "$status" -eq 1 ]]
	[[ "$output" == "" ]]
}

@test "templates: every template renders rows with printf" {
	for template in "$REPO_ROOT"/templates/*.tmpl; do
		run grep -c 'printf "%s  %s' "$template"

		[[ "$status" -eq 0 ]]
		[[ "$output" -ge 2 ]] # one header row and one row in the range
	done
}
