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
  nazoplugSrc ? null,
}:

let
  config = if nazoplugSrc == null then configSrc else pkgs.runCommand "nazovim-config" { } ''
    mkdir -p $out/lua/nazoplug
    cp -r ${configSrc}/. $out/
    cp -r ${nazoplugSrc}/. $out/lua/nazoplug/
  '';
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
        pkgs.gnumake
        pkgs.nodejs_latest
        pkgs.tree-sitter
        pkgs.clang-tools
        pkgs.jdt-language-server
        pkgs.ruby
      ];
      text = ''
        APPNAME="nvim-nazozokc"
        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME"
        DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME"
        export NVIM_APPNAME="$APPNAME"
        export NAZOVIM_PLUGIN_MANAGER="nazoplug"
        if [ -L "$CONFIG_DIR" ]; then
          rm "$CONFIG_DIR"
        elif [ -d "$CONFIG_DIR" ]; then
          rm -rf "$CONFIG_DIR"
        fi
        ln -s ${config} "$CONFIG_DIR"
        mkdir -p "$DATA_DIR"
        if [ ! -f "$DATA_DIR/nazoplug-lock.json" ] && [ -f "$CONFIG_DIR/nazoplug-lock.json" ]; then
          cp "$CONFIG_DIR/nazoplug-lock.json" "$DATA_DIR/nazoplug-lock.json"
        fi
        exec nvim "$@"
      '';
    };

    # nix build .#config → 設定ファイル一式
    config = config;
  };
}
