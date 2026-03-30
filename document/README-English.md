# NazoVim

```text
█   █  ███  █████  ███  █   █ ███ █   █
██  █ █   █     █ █   █ █   █  █  ██ ██
█ █ █ █   █    █  █   █ █   █  █  █ █ █
█  ██ █████   █   █   █ █   █  █  █   █
█   █ █   █  █    █   █  █ █   █  █   █
█   █ █   █ █     █   █  █ █   █  █   █
█   █ █   █ █████  ███    █   ███ █   █
```

**A personal Neovim distribution by [nazozokc:NazoVim-org](https://github.com/nazozokc)**

[![CI](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml/badge.svg)](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blueviolet?logo=neovim)
![Nix](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)

> **Note:** The CI pipeline (`nvim.yml`) runs in a Nix environment and does
> not test the plain `clone` installation path. If you install without Nix,
> please verify startup manually with `nvim --headless +q`.

---

## ✨ About

<!-- markdownlint-disable MD013 -->
**nazovim** is a personal Neovim distribution tailored for CLI/TUI-centric workflows.
Built on the [kanagawa](https://github.com/rebelot/kanagawa.nvim) color scheme and aggressive lazy-loading via [lazy.nvim](https://github.com/folke/lazy.nvim), it comes with everything needed for TypeScript, Lua, Nix, Ruby, and more.

> Distributed as a Nix flake — run it instantly in an isolated environment with a single `nix run` command.
<!-- markdownlint-enable MD013 -->

---

## 🖼️ Screenshots

> _Coming soon_

---

## 🚀 Features

<!-- markdownlint-disable MD013 -->
- **⚡ Fast startup** — Aggressive lazy-loading with lazy.nvim. Anything that can wait is deferred to `VeryLazy`
- **🔧 Full LSP** — Multi-language support: TypeScript / Lua / Ruby / Nix / C / Java / Zig and more. Dual setup with mason + manual (nixd)
- **🎨 kanagawa** — `kanagawa-dragon` theme with transparent background that blends seamlessly with your terminal
- **🧠 AI integration** — Supports both Claude Code (`claudecode.nvim`) and opencode (`opencode.nvim`)
- **🌊 snacks.nvim** — Dashboard, Picker, Zen mode, and session management all unified in one plugin
- **🐛 DAP** — Minimal debug environment for JavaScript / TypeScript
- **📦 Nix-ready** — Isolated launch via `nix run` / LSP-equipped devShell via `nix develop`
- **🧪 Testing** — neotest with Jest / Vitest / Playwright adapters
- **🔍 Fuzzy finding** — snacks.nvim Picker (ivy layout) as primary, Telescope as secondary
- **📝 Treesitter textobjects** — High-precision text objects at function / class / argument granularity
<!-- markdownlint-enable MD013 -->

---

## 📋 Requirements

| Required | Version |
| -------- | ------- |
| Neovim | 0.10+ |
| Git | any |
| [Nerd Font](https://www.nerdfonts.com/) | Required for icons |

| Recommended | Purpose |
| ----------- | ------- |
| Nix (with flakes) | Isolated launch via `nix run` / `nix develop` |
| Node.js | TypeScript LSP / prettier |
| lazygit | LazyGit integration |
| yazi | File manager integration |
| ripgrep | Grep search |
| fd | File search |

---

## 📦 Installation

### Option 1: `nix run` (try it without touching your config)

```bash
nix run github:nazozokc/nazozokc.nvim.config
```

<!-- markdownlint-disable MD013 -->
The configuration is deployed in isolation under `~/.config/nvim-nazozokc`, leaving your existing Neovim setup untouched.
<!-- markdownlint-enable MD013 -->

### Option 2: Clone (no Nix required)

<!-- markdownlint-disable MD013 -->
> **Warning**: This will overwrite your existing Neovim configuration. A backup is recommended.
<!-- markdownlint-enable MD013 -->
>
> ```bash
> mv ~/.config/nvim ~/.config/nvim.backup  # backup (optional)
> ```

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
nvim
```

On first launch, lazy.nvim will automatically install all plugins.

### Files safe to delete after cloning (Option 2)

- document/
- LICENSE
- SECURITY.md
- CONTRIBUTING.md

> `flake.nix` and `.github/` are required for CI.
> If you don't plan to submit PRs, you may delete only `.github/`.

---

## 🗂️ Directory Structure

```text
.
├── flake.nix             # Nix flake (nix run / nix develop)
├── init.lua              # Entry point & keymap definitions
├── lazy-lock.json        # Plugin version lock
├── lua/
│   ├── vim-options.lua   # Core vim settings
│   ├── plugins.lua       # lazy.nvim entry (empty = auto-loads plugins/ directory)
│   └── plugins/          # Plugin configs (one file per plugin)
├── template/             # File templates
│   ├── js/
│   ├── ts/
│   ├── lua/
│   ├── md/
│   └── project/
└── .github/
    ├── workflows/        # CI (nvim startup check / auto-merge)
    └── ISSUE_TEMPLATE/   # Bug report / Feature request / Plugin proposal
```

---

## 🔌 Plugins

### LSP / Completion

| Plugin | Purpose |
| ------ | ------ |
| nvim-lspconfig + mason | LSP management |
| typescript-tools.nvim | TypeScript-specific LSP (performance-tuned) |
| nvim-cmp | Completion engine |
| LuaSnip + denippet.vim | Snippets (VSCode-compatible) |
| lspsaga.nvim | Enhanced LSP UI |
| actions-preview.nvim | Code action preview |
| conform.nvim | Formatter (stylua / prettier / etc.) |
| none-ls.nvim | Additional diagnostics (rubocop, etc.) |
| fidget.nvim | LSP progress display |
| tiny-inline-diagnostic.nvim | Inline diagnostics |
| lazydev.nvim | Enhanced Lua/Neovim API completion and type checking |

### Fuzzy Finder / Navigation

| Plugin | Purpose |
| ------ | ------ |
| snacks.nvim | Picker / Dashboard / Zen / Words / Session |
| telescope.nvim | Fuzzy finder (secondary) |
| oil.nvim | Buffer-based file explorer |
| neo-tree.nvim | Tree-style file explorer |
| yazi.nvim | yazi file manager integration |
| dropbar.nvim | Winbar / breadcrumbs |
| flash.nvim | Jump navigation (`<CR>` for smart jump) |
| aerial.nvim | Symbol outline |
| project.nvim | Automatic project root detection |

### UI / Appearance

| Plugin | Purpose |
| ------ | ------ |
| kanagawa.nvim | Color scheme (dragon + transparent) |
| lualine.nvim | Status line |
| barbar.nvim | Tab bar |
| noice.nvim | Command line UI / notifications |
| nvim-notify | Notification system |
| nvim-scrollbar / satellite.nvim | Scrollbar |
| modes.nvim | Mode-based cursor color change |
| nvim-illuminate | Highlight symbol under cursor |
| incline.nvim | Floating filename |
| todo-comments.nvim | Highlight TODO/FIXME and similar |
| render-markdown.nvim | Rich Markdown rendering |
| nvim-highlight-colors | Inline color code preview |

### Git (Plugins)

| Plugin | Purpose |
| ------ | ------ |
| gitsigns.nvim | Git diff sign column |
| diffview.nvim | Diff view / file history |
| lazygit.nvim | LazyGit integration |
| vim-fugitive | Git operations |
| octo.nvim | GitHub Issues / PRs / Notifications |

### Editor

| Plugin | Purpose |
| ------ | ------ |
| nvim-treesitter | Syntax highlighting / indentation |
| nvim-treesitter-textobjects | Function / class / argument text objects |
| nvim-autopairs | Automatic bracket closing |
| mini.ai / surround / comment | Text objects / surround / commenting |
| nvim-spider | CamelCase / snake_case-aware w/e/b |
| substitute.nvim | Register-based substitution |
| dial.nvim | Extended `<C-a>/<C-x>` increment |
| which-key.nvim | Keymap help |
| toggleterm.nvim | Floating terminal |
| kulala.nvim | REST client (.http files) |
| persistence.nvim | Session management |

### AI Integration

| Plugin | Purpose |
| ------ | ------ |
| claudecode.nvim | Claude Code integration |
| opencode.nvim | opencode integration |
| CopilotChat.nvim | GitHub Copilot Chat |
| copilot.lua | GitHub Copilot completion |

### Debug / Test

| Plugin | Purpose |
| ------ | ------ |
| nvim-dap + nvim-dap-ui | Debugger |
| nvim-dap-vscode-js | JS/TS debug adapter |
| neotest | Test runner |
| neotest-jest / vitest / playwright | Test adapters |
| nvim-coverage | Coverage display |

---

## ⌨️ Keymaps

`<Leader>` = `Space`

### General

| Key | Action |
| ---- | ----- |
| `<Leader><Leader>` | File search (snacks Picker) |
| `<Leader>/` | Live Grep |
| `<Leader>b` | Buffer list |
| `<Leader>r` | Recent files |
| `<Leader>h` | Clear search highlight |
| `<Leader>z` | Zen mode |
| `<Leader>m` | Oil file explorer |
| `<Leader>n` | Neo-tree |
| `<Leader>t` | Floating terminal |
| `<Leader>f` | Format |

### LSP

| Key | Action |
| ---- | ----- |
| `K` | Hover |
| `gd` | Go to definition |
| `ga` | Code action (Lspsaga) |
| `<Leader>ca` | Code action (preview) |
| `<Leader>gd` | Go to definition |
| `<Leader>gr` | References |
| `<Leader>oi` | Organize imports (TS) |
| `<Leader>ru` | Remove unused (TS) |

### Treesitter Textobjects

| Key | Action |
| ---- | ----- |
| `af` / `if` | outer / inner function |
| `ac` / `ic` | outer / inner class |
| `aa` / `ia` | outer / inner argument |
| `ai` / `ii` | outer / inner conditional |
| `al` / `il` | outer / inner loop |
| `ab` / `ib` | outer / inner block |
| `]f` / `[f` | Jump to next/prev function |
| `]c` / `[c` | Jump to next/prev class |
| `]a` / `[a` | Jump to next/prev argument |
| `<Leader>sn` | Swap with next argument |
| `<Leader>sp` | Swap with previous argument |

### Git (Keymaps)

| Key | Action |
| ---- | ----- |
| `<Leader>gd` | DiffviewOpen |
| `<Leader>gh` | File history |
| `<Leader>gH` | Branch history |
| `<Leader>gc` | Diffview close |
| `<Leader>gp` | Hunk preview |
| `<Leader>gt` | Blame toggle |

### Session

| Key | Action |
| ---- | ----- |
| `<Leader>qs` | Restore session |
| `<Leader>qS` | Select session |
| `<Leader>ql` | Restore last session |
| `<Leader>qd` | Stop saving session |

### AI

| Key | Action |
| ---- | ----- |
| `<Leader>ac` | Claude Code toggle |
| `<Leader>af` | Claude Code focus |
| `<Leader>ab` | Add current buffer |
| `<C-a>` | opencode ask |
| `<C-x>` | opencode select action |
| `<C-.>` | opencode toggle |

### DAP

| Key | Action |
| ---- | ----- |
| `<F5>` | Run / Continue |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<Leader>db` | Toggle breakpoint |
| `<Leader>du` | DAP UI toggle |

### Test

| Key | Action |
| ---- | ----- |
| `<leader>tr` | Run nearest test |
| `<leader>tR` | Run all tests |
| `<leader>tf` | Run tests in file |
| `<leader>to` | Toggle test output |

### Window / Buffer

| Key | Action |
| ---- | ----- |
| `<C-h/j/k/l>` | Window navigation (tmux-aware) |
| `<C-PageDown/Up>` | Switch buffer |
| `<C-t>` | New buffer |
| `<C-q>` | Close buffer |

---

## 🛠️ Maintenance

### Update plugins

```vim
:Lazy sync   " Update all plugins
:Lazy clean  " Remove unused plugins
:Lazy snapshot " Lock current versions
```

### Reload config

```vim
:Lazy reload   " Reload configuration
:source %      " Source current buffer
```

---

## 🔧 Customization

Any Lua file added under `lua/plugins/` will be auto-loaded.

```lua
-- lua/plugins/my-config.lua

-- Add a plugin
return {
  "folke/zen-mode.nvim",
  opts = {}
}
```

You can also override existing plugin settings in the same file:

```lua
return {
  "rebelot/kanagawa.nvim",
  opts = { transparent = false }
}
```

> **Note**: Only applies when installed via the Clone method (Option 2).

---

## 🏗️ Nix Integration

This distribution is fully managed as a Nix flake.

```bash
# Isolated launch (non-destructive)
nix run github:nazozokc/nazovim

# Dev shell with LSP/formatter included
nix develop github:nazozokc/nazovim

# Build config files only
nix build github:nazozokc/nazovim

# Supported platforms
# x86_64-linux / aarch64-linux / aarch64-darwin
```

---

## 🐛 Contributing

Issues and PRs are always welcome.
<!-- markdownlint-disable MD013 -->
For questions, head over to [GitHub Discussions](https://github.com/nazozokc/nazozokc.nvim.config/discussions).
<!-- markdownlint-enable MD013 -->

Issue templates are available for:

- 🐛 **Bug Report** — Include reproduction steps, Neovim version, and error logs
- ✨ **Feature Request** — Describe your motivation and proposed solution
- 🔌 **Plugin Proposal** — Include plugin name, URL, and a lazy.nvim config snippet

---

## 📄 License

MIT © [nazozokc](https://github.com/nazozokc)
