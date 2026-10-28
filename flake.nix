{
  description = "NazoVim-org's Neovim configuration";

  # ============================================================
  # monorepo structure:
  #   apps/nvim/       — Neovim configuration (init.lua, lua/, nazoplug-lock.json)
  #   packages/nix/    — Nix modules and package definitions
  #   template/        — File templates for new projects
  #   docs/            — Documentation
  # ============================================================

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        let
          neovim_12 = pkgs.wrapNeovim pkgs.neovim-unwrapped { };
          # apps/nvim/ 以下の設定ファイルを Nix store にコピー
          nvimConfig = pkgs.stdenv.mkDerivation {
            pname = "nazovim";
            version = "1.0.0";
            src = pkgs.lib.cleanSource ./apps/nvim;
            installPhase = ''
              mkdir -p $out/lua/nazoplug
              cp -r . $out/
              cp -r ${./apps/nazoplug/lua/nazoplug}/. $out/lua/nazoplug/
            '';
          };

          # NVIM_APPNAME で完全隔離して起動する wrapped neovim
          # nix run github:NazoVim-org/NazoVim で起動可能
          nvim-nazozokc = pkgs.writeShellApplication {
            name = "nvim";
            runtimeInputs = [
              neovim_12
              pkgs.git
              pkgs.gnumake
              pkgs.nodejs_latest
              pkgs.tree-sitter
              pkgs.clang-tools # clangd
              pkgs.jdt-language-server # jdtls
              pkgs.ruby
            ];
            text = ''
              APPNAME="nvim-nazozokc"
              CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME"
              DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME"
              export NVIM_APPNAME="$APPNAME"
              export NAZOVIM_PLUGIN_MANAGER="nazoplug"
              # symlink なら既存チェック不要、存在すれば上書き
              if [ -L "$CONFIG_DIR" ]; then
                rm "$CONFIG_DIR"
              elif [ -d "$CONFIG_DIR" ]; then
                rm -rf "$CONFIG_DIR"
              fi
              ln -s ${nvimConfig} "$CONFIG_DIR"
              # プラグインのデータディレクトリを事前に作成
              mkdir -p "$DATA_DIR"
              # 初回起動時に Nix store の lockfile を data dir にコピー
              if [ ! -f "$DATA_DIR/nazoplug-lock.json" ] && [ -f "$CONFIG_DIR/nazoplug-lock.json" ]; then
                cp "$CONFIG_DIR/nazoplug-lock.json" "$DATA_DIR/nazoplug-lock.json"
              fi
              exec nvim "$@"
            '';
          };

        in
        {
          packages = {
            # nix build → result/bin/nvim
            default = nvim-nazozokc;

            # nix build .#config → 設定ファイル一式
            config = nvimConfig;
          };

          apps.default = {
            type = "app";
            program = "${nvim-nazozokc}/bin/nvim";
          };

          # nix develop → LSP / formatter が揃った開発シェル
          # NVIM_APPNAME も自動でセットされるので nvim を叩くだけで隔離環境に入る
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              neovim_12
              git
              bun
              deno
              nodejs_latest
              pnpm
              gnumake
              tree-sitter

              # LSP
              lua-language-server
              nixd
              nodePackages.typescript-language-server

              # Formatter
              stylua
              nixfmt-rfc-style
              nodePackages.prettier
            ];

            shellHook = ''
              export NVIM_APPNAME="nvim-nazozokc"
              export NAZOVIM_PLUGIN_MANAGER="nazoplug"

              CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/nvim-nazozokc"

              if [ ! -d "$CONFIG_DIR" ]; then
                echo "[nazozokc.nvim] Initializing config at $CONFIG_DIR ..."
                mkdir -p "$CONFIG_DIR"
                cp -r ${nvimConfig}/. "$CONFIG_DIR/"
                chmod -R u+w "$CONFIG_DIR"
              fi

              echo "nazozokc.nvim devShell"
              echo "  neovim : $(nvim --version | head -1)"
              echo "  lua-ls : $(lua-language-server --version 2>/dev/null || echo 'ok')"
              echo "  config : $CONFIG_DIR"
              echo "  NVIM_APPNAME=$NVIM_APPNAME (隔離済み)"
            '';
          };
        };
    };
}
