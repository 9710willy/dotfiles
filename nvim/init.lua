vim.g.mapleader = " "
vim.g.loaded_matchparen = 1

if vim.fn.executable('rg') == 1 then
    vim.g.rg_derive_root='true'
end

require'mappings'
require'plugins'
require'config'
