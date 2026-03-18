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

**Une distribution Neovim personnelle par [nazozokc](https://github.com/nazozokc)**

[![CI](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml/badge.svg)](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blueviolet?logo=neovim)
![Nix](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)

</div>

---

## ✨ À propos

**nazovim** est une distribution Neovim personnelle conçue pour les flux de travail CLI/TUI.
Basée sur le thème [kanagawa](https://github.com/rebelot/kanagawa.nvim) et [lazy.nvim](https://github.com/folke/lazy.nvim) pour un chargement différé rapide, elle inclut tout ce qu'il faut pour TypeScript, Lua, Nix, Ruby et plus encore.

> Distribuée sous forme de flake Nix — lancez-la instantanément dans un environnement isolé avec un simple `nix run`.

---

## 🖼️ Captures d'écran

> _Bientôt disponible_

---

## 🚀 Fonctionnalités

- **⚡ Démarrage rapide** — Chargement différé agressif via lazy.nvim
- **🔧 LSP complet** — Support multi-langages : TypeScript / Lua / Ruby / Nix / C / Java / Zig et plus
- **🎨 kanagawa** — Thème `kanagawa-dragon` + fond transparent qui se fond dans votre terminal
- **🧠 Intégration IA** — Claude Code (`claudecode.nvim`) et opencode (`opencode.nvim`) tous les deux supportés
- **🌊 snacks.nvim** — Dashboard, Picker, mode Zen et gestion de session unifiés
- **🐛 DAP** — Environnement de débogage JavaScript / TypeScript inclus
- **📦 Compatible Nix** — Lancement isolé avec `nix run` / devShell équipé LSP avec `nix develop`
- **🧪 Tests** — neotest + adaptateurs Jest / Vitest / Playwright
- **🔍 Recherche floue** — snacks.nvim Picker (layout ivy) en principal, Telescope en secondaire
- **📝 Textobjects Treesitter** — Textobjects précis au niveau fonction / classe / argument

---

## 📋 Prérequis

| Requis | Version |
|--------|---------|
| Neovim | 0.10+ |
| Git | toute version |
| [Nerd Font](https://www.nerdfonts.com/) | Requis pour les icônes |

| Recommandé | Utilité |
|------------|---------|
| Nix (avec flakes) | Lancement isolé `nix run` / `nix develop` |
| Node.js | LSP TypeScript / prettier |
| lazygit | Intégration LazyGit |
| yazi | Intégration gestionnaire de fichiers |
| ripgrep | Recherche grep |
| fd | Recherche de fichiers |

---

## 📦 Installation

### Méthode 1 : `nix run` (Recommandé / environnement Nix)

```bash
nix run github:nazozokc/nazozokc.nvim.config
```

La configuration est déployée de manière isolée dans `~/.config/nvim-nazozokc`, sans toucher à votre configuration Neovim existante.

### Méthode 2 : `nix develop` (devShell)

Entrez dans un shell de développement avec LSP et formateurs prêts.

```bash
nix develop github:nazozokc/nazovim
nvim  # démarre automatiquement avec NVIM_APPNAME=nvim-nazozokc
```

### Méthode 3 : Clone (sans Nix)

> **Attention** : Cela écrasera votre configuration Neovim existante. Sauvegarde recommandée.
>
> ```bash
> mv ~/.config/nvim ~/.config/nvim.backup
> ```

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
nvim
```

Au premier lancement, lazy.nvim installera automatiquement tous les plugins.

---

## 🗂️ Structure des répertoires

```
.
├── flake.nix             # Nix flake (nix run / nix develop)
├── init.lua              # Point d'entrée & définitions des raccourcis
├── lazy-lock.json        # Verrouillage des versions des plugins
├── lua/
│   ├── vim-options.lua   # Paramètres vim de base
│   ├── plugins.lua       # Entrée lazy.nvim (vide = charge plugins/ automatiquement)
│   └── plugins/          # Configurations des plugins (un fichier par plugin)
├── template/             # Modèles de fichiers
└── .github/
    ├── workflows/        # CI (vérification démarrage nvim / auto-merge)
    └── ISSUE_TEMPLATE/   # Rapport de bug / Demande de fonctionnalité / Proposition de plugin
```

---

## ⌨️ Raccourcis clavier

`<Leader>` = `Espace`

<details>
<summary><b>Général</b></summary>

| Touche | Action |
|--------|--------|
| `<Leader><Leader>` | Recherche de fichiers (snacks Picker) |
| `<Leader>g` | Recherche en direct (Live Grep) |
| `<Leader>b` | Liste des tampons |
| `<Leader>r` | Fichiers récents |
| `<Leader>h` | Effacer la surbrillance de recherche |
| `<Leader>z` | Mode Zen |
| `<Leader>m` | Explorateur de fichiers Oil |
| `<Leader>n` | Neo-tree |
| `<Leader>t` | Terminal flottant |
| `<Leader>f` | Formater le tampon |

</details>

<details>
<summary><b>LSP</b></summary>

| Touche | Action |
|--------|--------|
| `K` | Documentation au survol |
| `gd` | Aller à la définition |
| `ga` | Action de code (Lspsaga) |
| `<Leader>ca` | Action de code (aperçu) |
| `<Leader>gr` | Références |
| `<Leader>oi` | Organiser les imports (TS) |
| `<Leader>ru` | Supprimer les inutilisés (TS) |

</details>

<details>
<summary><b>Git</b></summary>

| Touche | Action |
|--------|--------|
| `<Leader>gd` | Ouvrir Diffview |
| `<Leader>gh` | Historique du fichier |
| `<Leader>gH` | Historique de la branche |
| `<Leader>gc` | Fermer Diffview |
| `<Leader>gp` | Aperçu du hunk |
| `<Leader>gt` | Basculer le blame |

</details>

<details>
<summary><b>IA</b></summary>

| Touche | Action |
|--------|--------|
| `<Leader>ac` | Basculer Claude Code |
| `<Leader>af` | Focuser Claude Code |
| `<Leader>ab` | Ajouter le tampon courant |
| `<C-a>` | Demander à opencode |
| `<C-x>` | Sélectionner une action opencode |
| `<C-.>` | Basculer opencode |

</details>

---

## 🏗️ Intégration Nix

```bash
# Lancement isolé
nix run github:nazozokc/nazovim

# Shell de développement avec LSP/formateur
nix develop github:nazozokc/nazovim

# Plateformes supportées
# x86_64-linux / aarch64-linux / aarch64-darwin
```

---

## 🐛 Contribution

Les issues et PRs sont les bienvenues.
Pour les questions, rendez-vous sur [GitHub Discussions](https://github.com/nazozokc/nazozokc.nvim.config/discussions).

---

## 📄 Licence

MIT © [nazozokc](https://github.com/nazozokc)
