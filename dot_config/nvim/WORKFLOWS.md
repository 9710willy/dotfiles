# Neovim Workflows Guide

Reference for the keymaps and commands in this config.
Leader is `<Space>`. Local leader is `,`.

## Quick Reference

| Action | Keybind | Description |
|--------|---------|-------------|
| Save | `<leader>w` or `<C-s>` (insert) | Save current buffer |
| Quit | `<leader>q` | Quit all |
| Save+Quit | `<leader>x` | Save and quit |
| Close buffer | `<leader>d` | Delete buffer (keeps window) |
| Yank to clipboard | `y+{motion}` | Yank into the `+` register |

---

## 1. Navigation & Motion

### Flash.nvim
- `z` - Jump to any visible character (type target chars)
- `Z` - Jump with treesitter nodes (select code blocks)
- `r` (operator-pending) - Remote flash for distant operations
- `R` (visual/operator) - Treesitter search across the file
- `<C-f>` (search cmdline) - Toggle flash labels in `/` search

### Window/Tab Movement
- `<C-h/j/k/l>` - Move between windows
- `<C-Left/Right>` - Move between tabs
- `{` / `}` - Previous/next symbol (active once Aerial is loaded)
- `5j` / `5k` - Counted jumps also land in the jumplist
- `<leader>j` - Telescope jumplist

### Harpoon
- `<leader>a` - Add file to the list
- `<leader>h` - Open the quick menu
- `<leader>1`..`<leader>4` - Jump to list entry

### Bracket Motions (mini.bracketed)
- `[` / `]` + suffix - Previous/next buffer, comment, diagnostic,
  quickfix entry, and more; see `:h mini.bracketed`

### Text Objects
- mini.ai: `i`/`a` + object, plus `in`/`an` (next) and `il`/`al` (last)
- nvim-various-textobjs: default maps enabled; see `:h nvim-various-textobjs`
- vim-wordmotion: `w`/`b`/`e` stop inside camelCase and snake_case words
- `ih` (operator/visual) - Git hunk

### Treesitter Selection
- `<C-Space>` - Start, then grow the selection node by node
- `<BS>` (visual) - Shrink the selection

---

## 2. LSP & Code Intelligence

### Definitions & References
- `gd` - Definition (Glance popup)
- `gD` - Declaration
- `gr` - References (Glance popup; LSP buffers only)
- `gi` - Implementation
- `gTD` - Type definition
- `gS` - Signature help
- `K` - Hover documentation (hover.nvim)
- `gK` - Hover with source selection

### Code Actions & Refactoring
- `gA` - Code actions (normal or visual)
- `<leader>rn` - Rename with live preview (inc-rename)
- `<leader>re` (visual) - Extract function
- `<leader>rv` (visual) - Extract variable
- `<leader>ri` - Inline variable
- `<leader>rb` / `<leader>rB` - Extract block / to file
- `<leader>rp` - Insert debug print
- `<leader>rc` - Clean up debug prints

### Diagnostics
- Signs in the sign column; virtual lines for the current line
- Inlay hints are on for servers that support them
- Trouble: `<leader>xx` toggle, `<leader>xd` buffer, `<leader>xs` symbols,
  `<leader>xr` LSP refs, `<leader>xl` loclist, `<leader>xq` qflist
- `[q` / `]q` - Previous/next Trouble or quickfix item

---

## 3. Completion (nvim-cmp)

In insert mode:
- `<Tab>` - Next item / jump forward in snippet
- `<S-Tab>` - Previous item / jump back in snippet
- `<CR>` - Confirm selection
- `<C-Space>` - Trigger completion
- `<C-e>` - Abort
- `<C-b>` / `<C-f>` - Scroll docs

Sources (priority order): LSP signature help, LSP, snippets, path, buffer.
Lua API completion comes from lazydev through the LSP source.

---

## 4. Git Workflow

### Neogit
- `<leader>g` - Open Neogit status

In the Neogit buffer:
- `s` - Stage file/hunk
- `u` - Unstage
- `c` - Commit
- `p` - Push
- `F` - Pull
- `b` - Branch operations
- `?` - Help

### Gitsigns (in-buffer)
- `]c` / `[c` - Next/previous hunk
- `<leader>hs` / `<leader>hr` - Stage/reset hunk (also visual)
- `<leader>hS` / `<leader>hR` - Stage/reset buffer
- `<leader>hp` / `<leader>hi` - Preview hunk (float/inline)
- `<leader>hb` - Blame line; `<leader>gb` - Toggle line blame
- `<leader>hd` / `<leader>hD` - Diff against index / last commit
- Stage a staged hunk again to unstage it

### Git Conflict
When conflicts occur:
- `co` - Choose ours
- `ct` - Choose theirs
- `cb` - Choose both
- `c0` - Choose none

### Git Links
- `<leader>gy` - Copy permalink to the current line/selection
- `<leader>gY` - Open the permalink in the browser
- `<leader>gB` - Copy blame link

### Diffview
- `:DiffviewOpen` - View all changes
- `:DiffviewFileHistory` - File history

---

## 5. File Navigation

### Telescope
- `<C-d>` - Find files
- `<C-g>` - Live grep
- `<C-a>` - Buffers
- `<C-s>` - Symbols (Aerial)
- `<leader>c` - Commands
- `<leader>j` - Jumplist
- `:Telescope undo` - Undo history tree

### Neo-tree
- `:Neotree` - File explorer (also opens when you edit a directory)
- `a` - Add file
- `d` - Delete
- `r` - Rename
- `c` - Copy
- `m` - Move

---

## 6. Editing

### Yank Ring (yanky)
- `p` / `P` - Put after/before
- `<C-p>` / `<C-n>` - Cycle yank history right after a put
- `]p` / `[p` - Put with adjusted indent

### Surround (mini.surround)
- `sa{motion}{char}` - Add surround
- `sd{char}` - Delete surround
- `sr{old}{new}` - Replace surround

Example: `saiw"` surrounds the word with quotes.

### Comments (mini.comment)
- `gc{motion}` - Comment lines
- `gcc` - Comment current line
- Visual select + `gc` - Comment selection

### Operators (mini.operators)
- `g=` - Evaluate
- `gx` - Exchange
- `gm` - Multiply (duplicate)
- `gs` - Sort
- `gr` - Replace with register (LSP buffers map `gr` to references instead)

Note: mini.align is installed, but mini.operators owns `g=`,
so alignment has no reachable mapping right now.

### Split/Join (mini.splitjoin)
- `gJ` - Toggle between single-line and multi-line

### Move Lines (mini.move)
- `Alt-h/j/k/l` - Move selection/line in that direction

### Search & Replace (Spectre)
- `<leader>S` - Toggle project-wide search and replace
- `<leader>sw` - Search current word (normal) or selection (visual)
- `<leader>sp` - Search in the current file

### Annotations (neogen)
- `,d` - Generate doc comment
- `,df` / `,dc` - Function / class doc comment

### Folds
- Treesitter folding; `za`/`zc`/`zo` as usual
- `zR` / `zM` - Open/close all folds (ufo)
- `zK` - Peek folded lines

---

## 7. REPL & Interactive Development

### Iron.nvim
- `<leader>rs` - Open REPL
- `<leader>rf` - Focus REPL
- `<leader>rr` - Restart REPL
- `<leader>rh` - Hide REPL
- `<C-CR>` - Send line/selection to REPL
- `<C-c>{motion}` - Send motion to REPL

Configured REPLs: Python (ptipython), OCaml (utop), Lua (croissant).

---

## 8. Debugging (DAP)

- `:Debug` or `<F5>` - Start/continue
- `:BreakpointToggle` - Toggle breakpoint
- `:DapREPL` - Open debug REPL
- `<F10>` / `<F11>` / `<F12>` - Step over / into / out

DAP UI opens on debug start. Adapters: debugpy, lldb-dap, nlua.

---

## 9. Formatting & Linting

### Format (conform.nvim)
- `<leader>f` - Format buffer (or selection)

Formatting is manual. There is no format-on-save.

### Lint (nvim-lint)
Runs on open, save, and leaving insert mode. Linters:
- Lua: selene
- JS/TS: eslint_d
- Shell: shellcheck
- C/C++: flawfinder
- LaTeX: chktex
- Vimscript: vint
- Commit messages: gitlint

### Rulebook
- `<leader>i` - Ignore lint rule at cursor
- `<leader>l` - Look up lint rule docs

---

## 10. Session Management

### Mini.sessions
- `<leader>s` - Save session (named after current directory)
- Sessions are listed on the start screen

---

## 11. Terminal

### Toggleterm
- `<leader>tt` - Toggle floating terminal
- `<leader>t1` / `<leader>t2` / `<leader>t3` - Numbered terminals
- `<Esc><Esc>` - Leave terminal mode
- flatten.nvim opens `nvim` calls from the terminal in the outer instance

---

## 12. Code Outline

### Aerial
- `:AerialToggle` - Toggle outline sidebar
- `{` / `}` - Jump between symbols (after Aerial loads)
- `<C-s>` - Fuzzy-find symbols via Telescope

### Barbecue
Breadcrumbs in the winbar show the current code context.

---

## 13. UI

### Noice
- Enhanced messages, cmdline, and popups
- Search shows at the bottom
- LSP progress comes from fidget.nvim, not noice

### Mini.clue
Pause after `<leader>`, `g`, `z`, `'`, `"`, `<C-w>` to see available keys.

### Focus.nvim
Auto-resizes windows to favor the active one.

---

## 14. Python

### Venv Selector
- `<leader>pv` - Select virtual environment

---

## Tips

1. Use Flash for movement: `z`, then type the target.
2. `<leader>rn` renames with a live preview.
3. `<leader>s` saves a session; pick it from the start screen.
4. `<leader>g` opens the full git workflow.
5. `<leader>rs` then `<C-CR>` sends code to a REPL.
6. `<leader>f` formats; saving does not format.

---

## Discovering More

- `:Lazy` - Plugin manager
- `:checkhealth` - Verify setup
- `:Telescope keymaps` - Search all keybindings
