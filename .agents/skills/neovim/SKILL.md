---
name: neovim
description: When editing NazoVim Neovim config, adding plugins, or optimizing startup time
---

# NazoVim Neovim Configuration Skill

## When to Use

- When adding or removing plugins with lazy.nvim
- When changing LSP, DAP, or formatter configuration
- When optimizing startup time

## Directory Structure

```text
lua/
├── config/
│   ├── options.lua   # vim.opt settings
│   ├── keymaps.lua   # Global keymaps
│   └── autocmds.lua  # Autocommands
├── plugins.lua       # Plugin category import definitions
└── plugins/          # Plugin configs (organized by category)
```

## Plugin Addition Checklist

1. Check if a plugin with the same role already exists
2. Determine appropriate lazy-loading event:

| Event         | Use Case                 |
| ------------- | ------------------------ |
| `VeryLazy`    | Colorschemes, UI plugins |
| `BufReadPre`  | File reading plugins     |
| `InsertEnter` | Completion, snippets     |
| `LspAttach`   | LSP-dependent plugins    |
| `cmd`         | Command-triggered only   |

3. Add to the appropriate category under `lua/plugins/`
4. Verify startup time: `nvim --startuptime /tmp/startuptime.log`

## Key Rules

- Never call `require()` outside of `config` (loads at startup)
- DAP and git plugins are prone to duplication — check carefully
- Use `event = "VeryLazy"` for visual plugins
- Keep configs minimal — leverage plugin defaults where possible

## Verification

```bash
# Startup check (no errors)
nvim --headless \
  --startuptime /tmp/startuptime.log \
  -c "lua vim.defer_fn(function() vim.cmd('qall!') end, 500)" \
  2>/tmp/nvim-stderr.log || true

# Check for errors
grep -E "(^E[0-9]+:|Error detected|Error in lua)" /tmp/nvim-stderr.log

# Check startup time
tail -5 /tmp/startuptime.log
```

## CI Workflow

The `nvim.yml` workflow runs on push to main and PRs:
- Installs plugins via `Lazy! sync`
- Checks Neovim starts without errors
- Uploads logs on failure
