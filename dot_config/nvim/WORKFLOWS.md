# Neovim workflows

Leader is `<Space>`. Local leader is `,`.

## Manage plugins

Neovim 0.12 manages plugins with `vim.pack`.

- Run `:lua vim.pack.update()` to review and install updates.
- Restart Neovim after an update.
- Run `:checkhealth` to check the setup.

The lock file is `nvim-pack-lock.json`.

## Find files and text

Mini Pick provides the main pickers.

- `<C-d>` finds files.
- `<C-g>` searches project text.
- `<C-a>` lists buffers.
- `<C-s>` lists document symbols.
- `<leader>c` lists commands.
- `<leader>j` lists jump locations.
- `<leader>xx` lists all diagnostics.
- `<leader>xd` lists diagnostics in the current buffer.
- `<leader>xr` lists references.

Use `<leader>e` to open netrw, Neovim's file explorer.

## Move and select

- `s` jumps with Flash.
- `S` selects a Tree-sitter target with Flash.
- `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move between windows.
- `<C-Left>` and `<C-Right>` move between tabs.
- `<C-Space>` grows the Tree-sitter selection.
- `<BS>` shrinks the Tree-sitter selection.
- `<leader>a` adds the current file to Harpoon.
- `<leader>h` opens the Harpoon menu.
- `<leader>1` through `<leader>4` open Harpoon entries.

Mini AI provides text objects. Vim Wordmotion makes `w`, `b`, and `e` stop inside
camel case and snake case words.

## Use LSP features

Neovim provides the LSP keys and completion UI.

- `gd` goes to a definition.
- `gD` goes to a declaration.
- `gri` goes to an implementation.
- `grr` lists references.
- `grt` goes to a type definition.
- `grn` renames a symbol.
- `gra` runs a code action.
- `gO` lists document symbols.
- `gS` shows signature help.
- `K` shows hover help.

The aliases `<leader>rn` and `gA` also rename and run code actions.

In insert mode:

- Completion opens as you type.
- `<C-Space>` asks the LSP server for completion.
- `<Tab>` and `<S-Tab>` move through items or snippet fields.
- `<CR>` accepts the selected item.

## Edit text

- `<leader>w` saves the current buffer.
- `<leader>d` deletes the current buffer.
- `<Esc>` clears search highlights.
- `gc{motion}` comments text. Use `gcc` for one line.
- `gza{motion}{char}` adds a surround.
- `gzd{char}` deletes a surround.
- `gzr{old}{new}` replaces a surround.
- `gJ` splits or joins a code block.
- `<leader>S` opens project search and replace.
- `<leader>f` formats the current buffer or selection.
- `,d` creates a documentation comment.

Tree-sitter provides folds. Use standard fold keys such as `za`, `zc`, `zo`,
`zR`, and `zM`.

## Use Git

- `<leader>g` opens Neogit.
- `]c` and `[c` move between changed hunks.
- `<leader>hs` stages or unstages a hunk.
- `<leader>hr` resets a hunk.
- `<leader>hp` previews a hunk.
- `<leader>gb` toggles line blame.
- `<leader>gy` copies a link to the current line or selection.
- `<leader>gY` opens that link.
- `:DiffviewOpen` opens the diff view.

## Run code

- `<leader>tt` opens a native terminal split.
- `<Esc><Esc>` leaves terminal mode.
- `<leader>rs` opens an Iron REPL.
- `<C-CR>` sends a line or selection to the REPL.
- `<F5>` starts or continues a debug session.
- `<F10>`, `<F11>`, and `<F12>` step over, into, and out.

## Save sessions

- `<leader>s` saves a session named after the current directory.
- The start screen lists saved sessions and recent files.
