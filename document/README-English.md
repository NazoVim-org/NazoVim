<div align="center">

```
█   █  ███  █████  ███  █   █ ███ █   █
██  █ █   █     █ █   █ █   █  █  ██ ██
█ █ █ █   █    █  █   █ █   █  █  █ █ █
█  ██ █████   █   █   █ █   █  █  █   █
█   █ █   █  █    █   █  █ █   █  █   █
█   █ █   █ █     █   █  █ █   █  █   █
█   █ █   █ █████  ███    █   ███ █   █
```

**A personal Neovim distribution by [nazozokc](https://github.com/nazozokc)**

[![CI](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml/badge.svg)](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blueviolet?logo=neovim)
![Nix](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)

</div>

---

## ✨ About

**nazovim** is a personal Neovim distribution built for CLI/TUI-centric workflows.
Built on the [kanagawa](https://github.com/rebelot/kanagawa.nvim) color scheme and [lazy.nvim](https://github.com/folke/lazy.nvim) for fast lazy loading, it comes with everything you need for TypeScript, Lua, Nix, Ruby, and more.

> Distributed as a Nix flake — launch instantly in an isolated environment with a single `nix run`.

---

## 🖼️ Screenshots

> _Coming soon_

---

## 🚀 Features

- **⚡ Fast startup** — Aggressive lazy loading via lazy.nvim. Anything that can wait is deferred to VeryLazy
- **🔧 Full LSP** — Multi-language support: TypeScript / Lua / Ruby / Nix / C / Java / Zig and more. mason + manual (nixd) dual setup
- **🎨 kanagawa** — `kanagawa-dragon` theme + transparent background that blends with your terminal
- **🧠 AI integration** — Both Claude Code (`claudecode.nvim`) and opencode (`opencode.nvim`) supported
- **🌊 snacks.nvim** — Dashboard, Picker, Zen mode, and session management unified in one plugin
- **🐛 DAP** — JavaScript / TypeScript debug environment included with minimal config
- **📦 Nix-ready** — Isolated launch with `nix run` / LSP-equipped devShell with `nix develop`
- **🧪 Testing** — neotest + Jest / Vitest / Playwright adapters
- **🔍 Fuzzy finding** — snacks.nvim Picker (ivy layout) as main, Telescope as secondary
- **📝 Treesitter textobjects** — High-precision textobjects at function / class / argument level

---

## 📋 Requirements

| Required | Version |
|----------|---------|
| Neovim | 0.10+ |
| Git | any |
| [Nerd Font](https://www.nerdfonts.com/) | Required for icons |

| Recommended | Purpose |
|-------------|---------|
| Nix (with flakes) | `nix run` / `nix develop` isolated launch |
| Node.js | TypeScript LSP / prettier |
| lazygit | LazyGit integration |
| yazi | File manager integration |
| ripgrep | Grep search |
| fd | File search |

---

## 📦 Installation

### Method 1: `nix run` (Recommended / Nix environment)

```bash
nix run github:nazozokc/nazozokc.nvim.config
```

Config is deployed in isolation to `~/.config/nvim-nazozokc`, leaving your existing Neovim setup untouched.

### Method 2: `nix develop` (devShell)

Enter a dev shell with LSP and formatters ready to go.

```bash
nix develop github:nazozokc/nazovim
nvim  # auto-launches with NVIM_APPNAME=nvim-nazozokc
```

### Method 3: Clone (no Nix required)

> **Note**: This will overwrite your existing Neovim config. Backup recommended.
>
> ```bash
> mv ~/.config/nvim ~/.config/nvim.backup
> ```

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
nvim
```

On first launch, lazy.nvim will automatically install all plugins.

---

## 🗂️ Directory Structure

```
.
├── flake.nix             # Nix flake (nix run / nix develop)
├── init.lua              # Entry point & keymap definitions
├── lazy-lock.json        # Plugin version lock
├── lua/
│   ├── vim-options.lua   # Basic vim settings
│   ├── plugins.lua       # lazy.nvim entry (empty = auto-loads plugins/)
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

<details>
<summary><b>LSP / Completion</b></summary>

| Plugin | Purpose |
|--------|---------|
| nvim-lspconfig + mason | LSP management |
| typescript-tools.nvim | TypeScript-dedicated LSP (optimized) |
| nvim-cmp | Completion engine |
| LuaSnip + denippet.vim | Snippets (VSCode-compatible) |
| lspsaga.nvim | LSP UI enhancements |
| actions-preview.nvim | Code action preview |
| conform.nvim | Formatter (stylua / prettier etc.) |
| none-ls.nvim | Additional diagnostics (rubocop etc.) |
| fidget.nvim | LSP progress display |
| tiny-inline-diagnostic.nvim | Inline diagnostics |
| lazydev.nvim | Lua/Neovim API completion & type checking |

</details>

<details>
<summary><b>Fuzzy Finder / Navigation</b></summary>

| Plugin | Purpose |
|--------|---------|
| snacks.nvim | Picker / Dashboard / Zen / Words / Session |
| telescope.nvim | Fuzzy finder (secondary) |
| oil.nvim | Buffer-based file explorer |
| neo-tree.nvim | Tree-style file explorer |
| yazi.nvim | yazi file manager integration |
| dropbar.nvim | Winbar / breadcrumbs |
| flash.nvim | Jump (`<CR>` for smart jump) |
| aerial.nvim | Symbol outline |
| project.nvim | Auto project root detection |

</details>

<details>
<summary><b>UI</b></summary>

| Plugin | Purpose |
|--------|---------|
| kanagawa.nvim | Color scheme (dragon + transparent) |
| lualine.nvim | Status line |
| barbar.nvim | Tab bar |
| noice.nvim | Command line UI / notifications |
| nvim-notify | Notification system |
| nvim-scrollbar / satellite.nvim | Scrollbar |
| modes.nvim | Mode-dependent cursor color |
| nvim-illuminate | Symbol highlight under cursor |
| incline.nvim | Floating filename |
| todo-comments.nvim | TODO/FIXME highlights |
| render-markdown.nvim | Rich Markdown rendering |
| nvim-highlight-colors | Inline color code preview |

</details>

<details>
<summary><b>Git</b></summary>

| Plugin | Purpose |
|--------|---------|
| gitsigns.nvim | Git diff sign column |
| diffview.nvim | Diff view / file history |
| lazygit.nvim | LazyGit integration |
| vim-fugitive | Git operations |
| octo.nvim | GitHub Issue / PR / Notification |

</details>

<details>
<summary><b>Editor</b></summary>

| Plugin | Purpose |
|--------|---------|
| nvim-treesitter | Syntax highlight / indent |
| nvim-treesitter-textobjects | Function / class / argument textobjects |
| nvim-autopairs | Auto bracket completion |
| mini.ai / surround / comment | Textobjects / Surround / Comments |
| nvim-spider | CamelCase/snake_case w/e/b |
| substitute.nvim | Register-based substitution |
| dial.nvim | Extended `<C-a>/<C-x>` increment |
| which-key.nvim | Keymap help |
| toggleterm.nvim | Floating terminal |
| kulala.nvim | REST client (.http files) |
| persistence.nvim | Session management |

</details>

<details>
<summary><b>AI</b></summary>

| Plugin | Purpose |
|--------|---------|
| claudecode.nvim | Claude Code integration |
| opencode.nvim | opencode integration |
| CopilotChat.nvim | GitHub Copilot Chat |
| copilot.lua | GitHub Copilot completion |

</details>

<details>
<summary><b>Debug / Test</b></summary>

| Plugin | Purpose |
|--------|---------|
| nvim-dap + nvim-dap-ui | Debugger |
| nvim-dap-vscode-js | JS/TS debug adapter |
| neotest | Test runner |
| neotest-jest / vitest / playwright | Test adapters |
| nvim-coverage | Coverage display |

</details>

---

## ⌨️ Keymaps

`<Leader>` = `Space`

<details>
<summary><b>General</b></summary>

| Key | Action |
|-----|--------|
| `<Leader><Leader>` | File search (snacks Picker) |
| `<Leader>g` | Live Grep |
| `<Leader>b` | Buffer list |
| `<Leader>r` | Recent files |
| `<Leader>h` | Clear search highlight |
| `<Leader>z` | Zen mode |
| `<Leader>m` | Oil file explorer |
| `<Leader>n` | Neo-tree |
| `<Leader>t` | Floating terminal |
| `<Leader>f` | Format buffer |

</details>

<details>
<summary><b>LSP</b></summary>

| Key | Action |
|-----|--------|
| `K` | Hover |
| `gd` | Go to definition |
| `ga` | Code action (Lspsaga) |
| `<Leader>ca` | Code action (preview) |
| `<Leader>gd` | Go to definition |
| `<Leader>gr` | References |
| `<Leader>oi` | Organize imports (TS) |
| `<Leader>ru` | Remove unused (TS) |

</details>

<details>
<summary><b>Git</b></summary>

| Key | Action |
|-----|--------|
| `<Leader>gd` | DiffviewOpen |
| `<Leader>gh` | File history |
| `<Leader>gH` | Branch history |
| `<Leader>gc` | Diffview Close |
| `<Leader>gp` | Preview hunk |
| `<Leader>gt` | Blame toggle |

</details>

<details>
<summary><b>AI</b></summary>

| Key | Action |
|-----|--------|
| `<Leader>ac` | Toggle Claude Code |
| `<Leader>af` | Focus Claude Code |
| `<Leader>ab` | Add current buffer |
| `<C-a>` | opencode ask |
| `<C-x>` | opencode select action |
| `<C-.>` | opencode toggle |

</details>

<details>
<summary><b>DAP</b></summary>

| Key | Action |
|-----|--------|
| `<F5>` | Continue |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<Leader>db` | Toggle breakpoint |
| `<Leader>du` | DAP UI toggle |

</details>

---

## 🏗️ Nix Integration

```bash
# Isolated launch (no config pollution)
nix run github:nazozokc/nazovim

# Dev shell with LSP/formatter
nix develop github:nazozokc/nazovim

# Supported platforms
# x86_64-linux / aarch64-linux / aarch64-darwin
```

---

## 🐛 Contributing

Issues and PRs are welcome.
For questions, head to [GitHub Discussions](https://github.com/nazozokc/nazozokc.nvim.config/discussions).

---

## 📄 License

MIT © [nazozokc](https://github.com/nazozokc)
