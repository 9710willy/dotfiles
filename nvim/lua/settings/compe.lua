local imap = require('utils/keymap').imap
vim.g.loaded_compe_treesitter = true
vim.g.loaded_compe_snippets_nvim = true
vim.g.loaded_compe_spell = true
vim.g.loaded_compe_tags = true
vim.g.loaded_compe_ultisnips = true
vim.g.loaded_compe_vim_lsc = true
vim.g.loaded_compe_vim_lsp = true

require('compe').setup {
  enabled = true,
  debug = false,
  min_length = 1,
  preselect = 'always',
  source = {path = true, buffer = true, nvim_lsp = true, nvim_lua = true, vsnip = true}
}

local opts = {noremap = true, silent = true, expr = true}
imap('<C-n>', [[compe#complete()]], opts)
imap('<CR>', [[compe#confirm('<cr>')]], opts)
imap('<C-e>', [[compe#close('<c-e>')]], opts)
