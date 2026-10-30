#!/usr/bin/env bash
set -eu
launcher="$1"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/tmp" "$test_root/config" "$test_root/data"
printf 'keep\n' > "$test_root/config/sentinel"
printf 'keep\n' > "$test_root/data/sentinel"
export TMPDIR="$test_root/tmp"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache"
export XDG_STATE_HOME="$test_root/state"
printf '%s\n' 'return { plugins = { ["kanagawa.nvim"] = "VeryLazy" } }' > "$test_root/startup.lua"
export NAZOVIM_STARTUP_CONFIG="$test_root/startup.lua"
"$launcher" --temporary --headless \
  -c 'lua assert(vim.fn.exists(":NazoHelp") == 2); assert(require("nazoplug").by_name["kanagawa.nvim"].lazy)' \
  -c 'qall!'
test "$(cat "$test_root/config/sentinel")" = keep
test "$(cat "$test_root/data/sentinel")" = keep
test ! -e "$test_root/config/nvim-nazozokc"
test -z "$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -print -quit)"
echo 'temporary session: isolated state cleaned, existing files preserved'
