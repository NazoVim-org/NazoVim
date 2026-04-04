# Known Issues

## typescript-tools.nvim: Unknown filetype warnings

`:LspInfo` で `javascript.jsx` / `typescript.tsx` の WARNING が表示されるが、
typescript-tools.nvim 内部の filetype 登録に起因するため NazoVim 側での修正は不可。
upstream: [typescript-tools.nvim](https://github.com/pmizio/typescript-tools.nvim)
