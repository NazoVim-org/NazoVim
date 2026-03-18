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

**[nazozokc](https://github.com/nazozokc) 的个人 Neovim 发行版**

[![CI](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml/badge.svg)](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blueviolet?logo=neovim)
![Nix](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)

</div>

---

## ✨ 关于 nazovim

**nazovim** 是一个专为 CLI/TUI 工作流打造的个人 Neovim 发行版。
以 [kanagawa](https://github.com/rebelot/kanagawa.nvim) 配色方案和 [lazy.nvim](https://github.com/folke/lazy.nvim) 快速懒加载为基础，内置了 TypeScript、Lua、Nix、Ruby 等语言开发所需的一切。

> 以 Nix flake 形式分发——一条 `nix run` 命令即可在隔离环境中即时启动。

---

## 🖼️ 截图

> _即将推出_

---

## 🚀 特性

- **⚡ 快速启动** — 通过 lazy.nvim 实现激进的懒加载
- **🔧 完整 LSP** — 多语言支持：TypeScript / Lua / Ruby / Nix / C / Java / Zig 等
- **🎨 kanagawa** — `kanagawa-dragon` 主题 + 透明背景，与终端完美融合
- **🧠 AI 集成** — 同时支持 Claude Code（`claudecode.nvim`）和 opencode（`opencode.nvim`）
- **🌊 snacks.nvim** — Dashboard、Picker、禅模式和会话管理一体化
- **🐛 DAP** — 内置 JavaScript / TypeScript 调试环境
- **📦 Nix 支持** — `nix run` 隔离启动 / `nix develop` 提供带 LSP 的开发 Shell
- **🧪 测试** — neotest + Jest / Vitest / Playwright 适配器
- **🔍 模糊查找** — snacks.nvim Picker（ivy 布局）为主，Telescope 为辅
- **📝 Treesitter 文本对象** — 函数/类/参数级别的高精度文本对象

---

## 📋 环境要求

| 必需 | 版本 |
|------|------|
| Neovim | 0.10+ |
| Git | 任意版本 |
| [Nerd Font](https://www.nerdfonts.com/) | 图标显示所需 |

| 推荐 | 用途 |
|------|------|
| Nix（支持 flakes） | `nix run` / `nix develop` 隔离启动 |
| Node.js | TypeScript LSP / prettier |
| lazygit | LazyGit 集成 |
| yazi | 文件管理器集成 |
| ripgrep | Grep 搜索 |
| fd | 文件搜索 |

---

## 📦 安装

### 方式一：`nix run`（推荐 / Nix 环境）

```bash
nix run github:nazozokc/nazozokc.nvim.config
```

配置将隔离部署到 `~/.config/nvim-nazozokc`，不会影响现有的 Neovim 配置。

### 方式二：`nix develop`（devShell）

进入包含 LSP 和格式化工具的开发 Shell。

```bash
nix develop github:nazozokc/nazovim
nvim  # 自动以 NVIM_APPNAME=nvim-nazozokc 启动
```

### 方式三：克隆（无需 Nix）

> **注意**：这将覆盖现有的 Neovim 配置，建议先备份。
>
> ```bash
> mv ~/.config/nvim ~/.config/nvim.backup
> ```

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
nvim
```

首次启动时，lazy.nvim 将自动安装所有插件。

---

## 🗂️ 目录结构

```
.
├── flake.nix             # Nix flake (nix run / nix develop)
├── init.lua              # 入口点 & 快捷键定义
├── lazy-lock.json        # 插件版本锁定文件
├── lua/
│   ├── vim-options.lua   # 基础 Vim 设置
│   ├── plugins.lua       # lazy.nvim 入口（空 = 自动加载 plugins/ 目录）
│   └── plugins/          # 插件配置（每个插件一个文件）
├── template/             # 文件模板
└── .github/
    ├── workflows/        # CI（nvim 启动检查 / 自动合并）
    └── ISSUE_TEMPLATE/   # Bug 报告 / 功能请求 / 插件提案
```

---

## ⌨️ 快捷键

`<Leader>` = `空格键`

<details>
<summary><b>基础</b></summary>

| 按键 | 动作 |
|------|------|
| `<Leader><Leader>` | 文件搜索（snacks Picker） |
| `<Leader>g` | 实时 Grep |
| `<Leader>b` | 缓冲区列表 |
| `<Leader>r` | 最近文件 |
| `<Leader>h` | 清除搜索高亮 |
| `<Leader>z` | 禅模式 |
| `<Leader>m` | Oil 文件管理器 |
| `<Leader>n` | Neo-tree |
| `<Leader>t` | 浮动终端 |
| `<Leader>f` | 格式化缓冲区 |

</details>

<details>
<summary><b>LSP</b></summary>

| 按键 | 动作 |
|------|------|
| `K` | 悬停文档 |
| `gd` | 跳转到定义 |
| `ga` | 代码操作（Lspsaga） |
| `<Leader>ca` | 代码操作（预览） |
| `<Leader>gr` | 引用列表 |
| `<Leader>oi` | 整理导入（TS） |
| `<Leader>ru` | 删除未使用项（TS） |

</details>

<details>
<summary><b>Git</b></summary>

| 按键 | 动作 |
|------|------|
| `<Leader>gd` | 打开 Diffview |
| `<Leader>gh` | 文件历史 |
| `<Leader>gH` | 分支历史 |
| `<Leader>gc` | 关闭 Diffview |
| `<Leader>gp` | 预览 Hunk |
| `<Leader>gt` | 切换 Blame |

</details>

<details>
<summary><b>AI</b></summary>

| 按键 | 动作 |
|------|------|
| `<Leader>ac` | 切换 Claude Code |
| `<Leader>af` | 聚焦 Claude Code |
| `<Leader>ab` | 添加当前缓冲区 |
| `<C-a>` | 向 opencode 提问 |
| `<C-x>` | 选择 opencode 操作 |
| `<C-.>` | 切换 opencode |

</details>

---

## 🏗️ Nix 集成

```bash
# 隔离启动
nix run github:nazozokc/nazovim

# 带 LSP/格式化工具的开发 Shell
nix develop github:nazozokc/nazovim

# 支持的平台
# x86_64-linux / aarch64-linux / aarch64-darwin
```

---

## 🐛 贡献

欢迎提交 Issue 和 PR。
如有问题，请前往 [GitHub Discussions](https://github.com/nazozokc/nazozokc.nvim.config/discussions)。

---

## 📄 许可证

MIT © [nazozokc](https://github.com/nazozokc)
