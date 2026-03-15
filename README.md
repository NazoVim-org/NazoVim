# Neovim Configuration

このディレクトリは nazozokc/nazozokc.nvim.config リポジトリの Neovim 設定です。  
lazy.nvim をプラグインマネージャーとして使用しています。

---

## 特徴

- **軽量・高速・充実**: lazy.nvim による遅延読み込み
- **LSP 完備**: TypeScript, Lua, Ruby, Nix, HTML など標準サポート
- **モダンUI**: カスタムダッシュボード、ステータスライン、ファジーファインダー
- **Treesitter**: シンタックスハイライト・インデント
- **DAP統合**: デバッグ機能
- **テンプレート**: 各種ファイルタイプ用テンプレート

---

## ディレクトリ構成

```
nvim/
├── init.lua              # エントリーポイント・キーマップ
├── lazy-lock.json        # プラグインバージョンロック
├── lua/
│   ├── plugins.lua       # プラグイン定義（空）
│   ├── vim-options.lua   # 基本設定
│   └── plugins/          # プラグイン設定（各ファイル）
└── template/             # ファイルテンプレート
    ├── js/
    ├── lua/
    ├── md/
    ├── project/
    └── ts/
```

---

## 主要プラグイン

### LSP / 補完

| プラグイン      | 用途                       |
| --------------- | -------------------------- |
| nvim-lspconfig  | LSP設定                    |
| nvim-cmp        | 補完エンジン               |
| LuaSnip         | スニペット                 |
| Lspsaga         | LSP UI拡張                 |
| actions-preview | コードアクションプレビュー |

### Fuzzy Finder / ナビゲーション

| プラグイン     | 用途                        |
| -------------- | --------------------------- |
| snacks.nvim    | Picker, Dashboard, Zen mode |
| telescope.nvim | ファジーファインダー        |
| oil.nvim       | ファイルエクスプローラー    |
| dropbar.nvim   | Winbar / パンくずリスト     |
| flash.nvim     | ジャンプ                    |

### UI / 見た目

| プラグイン     | 用途             |
| -------------- | ---------------- |
| kanagawa.nvim  | カラースキーム   |
| lualine.nvim   | ステータスライン |
| noice.nvim     | コマンドラインUI |
| nvim-notify    | 通知             |
| nvim-scrollbar | スクロールバー   |

### Git

| プラグイン    | 用途         |
| ------------- | ------------ |
| gitsigns.nvim | Git sign     |
| lazygit.nvim  | LazyGit 統合 |
| octo.nvim     | GitHub 統合  |

### エディタ機能

| プラグイン      | 用途                   |
| --------------- | ---------------------- |
| nvim-treesitter | シンタックスハイライト |
| nvim-autopairs  | 括弧補完               |
| Comment.nvim    | コメントアウト         |
| substitute.nvim | 置換                   |
| which-key.nvim  | キーマップヘルプ       |
| toggleterm.nvim | ターミナル             |

### デバッグ / テスト

| プラグイン | 用途           |
| ---------- | -------------- |
| nvim-dap   | デバッガー     |
| neotest    | テストランナー |

---

## キーマップ

### Leader キー

`<Leader>` = `Space`

### 基本

| キー               | 動作               |
| ------------------ | ------------------ |
| `<Leader><Leader>` | ファイル検索       |
| `<Leader>g`        | Grep               |
| `<Leader>b`        | バッファ一覧       |
| `<Leader>r`        | 最近使ったファイル |
| `<Leader>h`        | 検索ハイライト解除 |
| `<Leader>z`        | Zen mode           |

### LSP

| キー         | 動作                       |
| ------------ | -------------------------- |
| `K`          | ホバー                     |
| `gd`         | 定義へ移動                 |
| `ga`         | コードアクション (Lspsaga) |
| `<Leader>ca` | コードアクション (preview) |
| `<Leader>gd` | 定義へ移動                 |
| `<Leader>gr` | 参照一覧                   |

### UI

| キー         | 動作                   |
| ------------ | ---------------------- |
| `<Leader>t`  | ターミナル             |
| `<Leader>c`  | 設定ディレクトリを Oil で開く |
| `<Leader>e`  | Trouble (診断一覧)     |
| `<Leader>so` | SymbolsOutline         |
| `<Leader>;`  | Dropbar pick           |
| `<F2>`       | Twilight               |

### DAP

| キー         | 動作                 |
| ------------ | -------------------- |
| `<F5>`       | 実行 / 継続          |
| `<F10>`      | ステップオーバー     |
| `<F11>`      | ステップイン         |
| `<F12>`      | ステップアウト       |
| `<Leader>db` | ブレークポイント切替 |

### ウィンドウ移動

| キー    | 動作     |
| ------- | -------- |
| `<C-h>` | 左へ移動 |
| `<C-j>` | 下へ移動 |
| `<C-k>` | 上へ移動 |
| `<C-l>` | 右へ移動 |

---

## LSP サポート

以下の言語サーバーを設定済み：

- **lua_ls** - Lua
- **ts_ls** - TypeScript / JavaScript
- **html** - HTML
- **solargraph** - Ruby
- **nixd・nil** - Nix
- **efm** - 汎用フォーマッター
- **nixfmt** - nixフォーマッター

---

## テンプレート

`template/` ディレクトリに各種テンプレートを配置：

- `js/` - JavaScript
- `ts/` - TypeScript
- `lua/` - Lua
- `md/` - Markdown
- `project/` - プロジェクト雛形

---

## 設定値

- インデント: 2スペース
- 行番号: 表示 + 相対行番号
- Insertモード中は相対行番号を無効化
- Swapファイル: 無効

---

## 使用方法

このリポジトリをクローンし、`~/.config/nvim` にシンボリックリンクを貼って使用します。

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
```

または、直接このディレクトリを `~/.config/nvim` に配置してください。