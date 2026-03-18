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

**[nazozokc](https://github.com/nazozokc)의 개인 Neovim 배포판**

[![CI](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml/badge.svg)](https://github.com/nazozokc/nazozokc.nvim.config/actions/workflows/nvim.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blueviolet?logo=neovim)
![Nix](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)

</div>

---

## ✨ 소개

**nazovim**은 CLI/TUI 중심 워크플로우를 위한 개인 Neovim 배포판입니다.
[kanagawa](https://github.com/rebelot/kanagawa.nvim) 컬러 스킴과 [lazy.nvim](https://github.com/folke/lazy.nvim)의 빠른 지연 로딩을 기반으로, TypeScript, Lua, Nix, Ruby 등의 개발에 필요한 모든 것이 갖춰져 있습니다.

> Nix flake로 배포되어 `nix run` 명령 하나로 격리된 환경에서 즉시 실행할 수 있습니다.

---

## 🖼️ 스크린샷

> _준비 중_

---

## 🚀 주요 기능

- **⚡ 빠른 시작** — lazy.nvim을 통한 적극적인 지연 로딩
- **🔧 완전한 LSP** — 다중 언어 지원: TypeScript / Lua / Ruby / Nix / C / Java / Zig 등
- **🎨 kanagawa** — `kanagawa-dragon` 테마 + 투명 배경으로 터미널과 자연스럽게 어우러짐
- **🧠 AI 통합** — Claude Code(`claudecode.nvim`)와 opencode(`opencode.nvim`) 모두 지원
- **🌊 snacks.nvim** — Dashboard, Picker, Zen 모드, 세션 관리 통합
- **🐛 DAP** — JavaScript / TypeScript 디버그 환경 내장
- **📦 Nix 지원** — `nix run`으로 격리 실행 / `nix develop`으로 LSP 완비 devShell 제공
- **🧪 테스트** — neotest + Jest / Vitest / Playwright 어댑터
- **🔍 퍼지 검색** — snacks.nvim Picker(ivy 레이아웃)를 메인으로, Telescope를 서브로 활용
- **📝 Treesitter 텍스트 객체** — 함수/클래스/인자 단위의 고정밀 텍스트 객체

---

## 📋 요구 사항

| 필수 | 버전 |
|------|------|
| Neovim | 0.10+ |
| Git | 모든 버전 |
| [Nerd Font](https://www.nerdfonts.com/) | 아이콘 표시에 필요 |

| 권장 | 용도 |
|------|------|
| Nix (flakes 지원) | `nix run` / `nix develop` 격리 실행 |
| Node.js | TypeScript LSP / prettier |
| lazygit | LazyGit 통합 |
| yazi | 파일 매니저 통합 |
| ripgrep | Grep 검색 |
| fd | 파일 검색 |

---

## 📦 설치

### 방법 1: `nix run` (권장 / Nix 환경)

```bash
nix run github:nazozokc/nazozokc.nvim.config
```

설정은 `~/.config/nvim-nazozokc`에 격리되어 배포되므로, 기존 Neovim 설정에 영향을 주지 않습니다.

### 방법 2: `nix develop` (devShell)

LSP와 포매터가 갖춰진 개발 셸에 진입합니다.

```bash
nix develop github:nazozokc/nazovim
nvim  # NVIM_APPNAME=nvim-nazozokc 로 자동 시작
```

### 방법 3: 클론 (Nix 불필요)

> **주의**: 기존 Neovim 설정을 덮어씁니다. 백업을 권장합니다.
>
> ```bash
> mv ~/.config/nvim ~/.config/nvim.backup
> ```

```bash
git clone https://github.com/nazozokc/nazozokc.nvim.config.git ~/.config/nvim
nvim
```

처음 실행 시 lazy.nvim이 모든 플러그인을 자동으로 설치합니다.

---

## 🗂️ 디렉토리 구조

```
.
├── flake.nix             # Nix flake (nix run / nix develop)
├── init.lua              # 진입점 & 키맵 정의
├── lazy-lock.json        # 플러그인 버전 잠금
├── lua/
│   ├── vim-options.lua   # 기본 Vim 설정
│   ├── plugins.lua       # lazy.nvim 진입점 (비어있음 = plugins/ 자동 로드)
│   └── plugins/          # 플러그인 설정 (1파일 1플러그인)
├── template/             # 파일 템플릿
└── .github/
    ├── workflows/        # CI (nvim 시작 체크 / 자동 머지)
    └── ISSUE_TEMPLATE/   # 버그 리포트 / 기능 요청 / 플러그인 제안
```

---

## ⌨️ 키맵

`<Leader>` = `스페이스`

<details>
<summary><b>기본</b></summary>

| 키 | 동작 |
|----|------|
| `<Leader><Leader>` | 파일 검색 (snacks Picker) |
| `<Leader>g` | Live Grep |
| `<Leader>b` | 버퍼 목록 |
| `<Leader>r` | 최근 파일 |
| `<Leader>h` | 검색 하이라이트 제거 |
| `<Leader>z` | Zen 모드 |
| `<Leader>m` | Oil 파일 탐색기 |
| `<Leader>n` | Neo-tree |
| `<Leader>t` | 플로팅 터미널 |
| `<Leader>f` | 버퍼 포맷 |

</details>

<details>
<summary><b>LSP</b></summary>

| 키 | 동작 |
|----|------|
| `K` | 호버 문서 |
| `gd` | 정의로 이동 |
| `ga` | 코드 액션 (Lspsaga) |
| `<Leader>ca` | 코드 액션 (미리보기) |
| `<Leader>gr` | 참조 목록 |
| `<Leader>oi` | Import 정리 (TS) |
| `<Leader>ru` | 미사용 제거 (TS) |

</details>

<details>
<summary><b>Git</b></summary>

| 키 | 동작 |
|----|------|
| `<Leader>gd` | Diffview 열기 |
| `<Leader>gh` | 파일 히스토리 |
| `<Leader>gH` | 브랜치 히스토리 |
| `<Leader>gc` | Diffview 닫기 |
| `<Leader>gp` | Hunk 미리보기 |
| `<Leader>gt` | Blame 토글 |

</details>

<details>
<summary><b>AI</b></summary>

| 키 | 동작 |
|----|------|
| `<Leader>ac` | Claude Code 토글 |
| `<Leader>af` | Claude Code 포커스 |
| `<Leader>ab` | 현재 버퍼 추가 |
| `<C-a>` | opencode 질문 |
| `<C-x>` | opencode 액션 선택 |
| `<C-.>` | opencode 토글 |

</details>

---

## 🏗️ Nix 통합

```bash
# 격리 실행
nix run github:nazozokc/nazovim

# LSP/포매터 완비 개발 셸
nix develop github:nazozokc/nazovim

# 지원 플랫폼
# x86_64-linux / aarch64-linux / aarch64-darwin
```

---

## 🐛 기여

Issue와 PR을 환영합니다.
질문은 [GitHub Discussions](https://github.com/nazozokc/nazozokc.nvim.config/discussions)에서 해주세요.

---

## 📄 라이선스

MIT © [nazozokc](https://github.com/nazozokc)
