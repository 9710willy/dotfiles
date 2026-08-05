# Neovim Workflows Guide

Your config is feature-rich. Here's how to leverage everything.

## Quick Reference

| Action | Keybind | Description |
|--------|---------|-------------|
| Save | `<leader>w` or `<C-s>` (insert) | Save current buffer |
| Quit | `<leader>q` | Quit all |
| Save+Quit | `<leader>x` | Save and quit |
| Close buffer | `<leader>d` | Delete buffer (keeps window) |

---

## 1. Navigation & Motion

### Flash.nvim - Lightning Fast Jumps
- `z` - Jump to any visible character (type target chars)
- `Z` - Jump using treesitter nodes (select code blocks)
- `r` (operator-pending) - Remote flash for distant operations
- `R` (visual/operator) - Treesitter search across file

### Window/Tab Movement
- `<C-h/j/k/l>` - Move between windows
- `<C-Left/Right>` - Move between tabs
- `{` / `}` - Jump to prev/next symbol (Aerial)

### Text Objects (mini.ai + various-textobjs)
Your config has extensive text objects:
- `i`/`a` prefix + object for inner/around
- `.` - Smart textsubject (expand selection contextually)
- `;` - Container outer, `i;` - Container inner

---

## 2. LSP & Code Intelligence

### Definitions & References
- `gd` - Go to definition (Glance popup)
- `gD` - Go to declaration
- `gr` - Find references (Glance popup)
- `gi` - Go to implementation
- `gTD` - Go to type definition
- `gS` - Signature help
- `K` - Hover documentation (hover.nvim)
- `gK` - Hover with source selection

### Code Actions & Refactoring
- `gA` - Code actions (normal or visual)
- `<leader>rn` - Rename symbol (inc-rename with preview)

### Diagnostics
- Errors show in sign column with icons
- Virtual lines appear for current line diagnostics
- Use Trouble.nvim: `:Trouble` for diagnostics list

---

## 3. Completion (nvim-cmp)

In insert mode:
- `<Tab>` - Next completion / jump in snippet
- `<S-Tab>` - Previous completion / jump back in snippet
- `<CR>` - Confirm selection
- `<C-Space>` - Trigger completion manually
- `<C-e>` - Abort completion
- `<C-b/f>` - Scroll docs

Sources (priority order): LSP signature, LSP, snippets, Lua, path

---

## 4. Git Workflow

### Neogit
- `<leader>g` - Open Neogit status

In Neogit buffer:
- `s` - Stage file/hunk
- `u` - Unstage
- `c` - Commit
- `p` - Push
- `F` - Pull
- `b` - Branch operations
- `?` - Help

### Gitsigns (in-buffer)
Signs appear in sign column. Use:
- `:Gitsigns preview_hunk` - Preview changes
- `:Gitsigns stage_hunk` - Stage current hunk
- `:Gitsigns reset_hunk` - Reset changes

### Git Conflict
When conflicts occur, keybinds appear:
- `co` - Choose ours
- `ct` - Choose theirs
- `cb` - Choose both
- `c0` - Choose none

### Diffview
- `:DiffviewOpen` - View all changes
- `:DiffviewFileHistory` - File history

---

## 5. File Navigation

### Telescope
- `:Telescope find_files` - Find files
- `:Telescope live_grep` - Search in files
- `:Telescope buffers` - Open buffers
- `:Telescope undo` - Undo history tree

### Neo-tree
- `:Neotree` - File explorer
- `a` - Add file
- `d` - Delete
- `r` - Rename
- `c` - Copy
- `m` - Move

---

## 6. Editing Superpowers

### Surround (mini.surround)
- `sa{motion}{char}` - Add surround
- `sd{char}` - Delete surround
- `sr{old}{new}` - Replace surround

Example: `saiw"` surrounds word with quotes

### Comments (mini.comment)
- `gc{motion}` - Comment lines
- `gcc` - Comment current line
- Visual select + `gc` - Comment selection

### Align (mini.align)
- `g=` - Start alignment with preview
- Select lines, then align by character

### Split/Join (mini.splitjoin)
- `gJ` - Toggle between single-line and multi-line

### Move Lines (mini.move)
- `Alt-h/j/k/l` - Move selection/line in that direction

### Operators (mini.operators)
- `g=` - Evaluate
- `gx` - Exchange
- `gm` - Multiply (duplicate)
- `gs` - Sort
- `g~` - Replace with register

---

## 7. REPL & Interactive Development

### Iron.nvim
- `<leader>rs` - Open REPL
- `<leader>rf` - Focus REPL
- `<leader>rr` - Restart REPL
- `<leader>rh` - Hide REPL
- `<C-CR>` - Send line/selection to REPL
- `<C-c>{motion}` - Send motion to REPL

Configured REPLs: Python (ptipython), OCaml (utop), Lua (croissant)

---

## 8. Debugging (DAP)

- `:Debug` - Start debugging
- `:BreakpointToggle` - Toggle breakpoint
- `:DapREPL` - Open debug REPL

DAP UI opens automatically on debug start.

---

## 9. Formatting & Linting

### Format (conform.nvim)
- `<leader>f` - Format buffer

Auto-formats on save for configured filetypes.

### Lint (nvim-lint)
Runs automatically on save. Linters configured:
- Lua: selene
- JS/TS: eslint_d
- Shell: shellcheck
- Python: (uses LSP)
- C/C++: flawfinder
- LaTeX: chktex

### Rulebook
- `<leader>i` - Ignore lint rule at cursor
- `<leader>l` - Look up lint rule docs

---

## 10. Session Management

### Mini.sessions
- `<leader>s` - Save session (named after current directory)
- Sessions auto-listed on start screen

---

## 11. Terminal

### Toggleterm
- `<C-\>` - Toggle terminal
- Works with flatten.nvim for nested nvim

---

## 12. Code Outline

### Aerial
- `:AerialToggle` - Toggle outline sidebar
- `{` / `}` - Jump between symbols

### Barbecue
Breadcrumb navigation in winbar showing current code context.

---

## 13. UI Enhancements

### Noice
- Messages, cmdline, and popups are enhanced
- Search shows at bottom
- LSP progress in corner

### Mini.clue
- Pause on leader/g/z/etc. to see available keybinds

### Focus.nvim
- Auto-resizes windows to focus on active one

---

## 14. Python-Specific

### Venv Selector
- `<leader>pv` - Select virtual environment

---

## Pro Tips

1. **Use Flash for everything**: `z` then type where you want to go
2. **Incremental rename**: `<leader>rn` shows live preview
3. **Session workflow**: `<leader>s` to save, then pick from start screen
4. **Git in-editor**: `<leader>g` for full git workflow
5. **REPL-driven dev**: `<leader>rs` then `<C-CR>` to send code
6. **Quick formatting**: `<leader>f` formats, but also auto-formats on save

---

## Discovering More

- `:Lazy` - Plugin manager
- `:Mason` - LSP/linter/formatter installer
- `:checkhealth` - Verify setup
- `:Telescope keymaps` - Search all keybindings
