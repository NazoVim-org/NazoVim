# NazoVim Nix package
#
# This package extracts the Neovim config from apps/nvim/ and wraps it
# with the necessary runtime inputs.
#
# The root flake.nix is the main entry point for `nix run github:NazoVim-org/NazoVim`.
# This module provides the underlying package derivation that the flake references.

{
  pkgs,
  lib,
  configSrc,
}:

let
  neovim_12 = pkgs.neovim.overrideAttrs (oldAttrs: {
    version = "0.12.0";
    src = pkgs.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v0.12.0";
      hash = "sha256-uWhrGAwQ2nnAkyJ46qGkYxJ5K1jtyUIQOAVu3yTlquk=";
    };
  });
in
{
  packages = {
    # nix build → result/bin/nvim
    default = pkgs.writeShellApplication {
      name = "nvim";
      runtimeInputs = [
        neovim_12
        pkgs.git
        pkgs.clang-tools
        pkgs.jdt-language-server
        pkgs.ruby
      ];
      text = ''
        APPNAME="nvim-nazozokc"
        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME"
        DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME"
        export NVIM_APPNAME="$APPNAME"
        if [ -L "$CONFIG_DIR" ]; then
          rm "$CONFIG_DIR"
        elif [ -d "$CONFIG_DIR" ]; then
          rm -rf "$CONFIG_DIR"
        fi
        ln -s ${configSrc} "$CONFIG_DIR"
        mkdir -p "$DATA_DIR"
        if [ ! -f "$DATA_DIR/lazy-lock.json" ] && [ -f "$CONFIG_DIR/lazy-lock.json" ]; then
          cp "$CONFIG_DIR/lazy-lock.json" "$DATA_DIR/lazy-lock.json"
        fi
        exec nvim "$@"
      '';
    };

    # nix build .#config → 設定ファイル一式
    config = configSrc;
  };
}
