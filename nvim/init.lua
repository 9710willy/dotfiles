vim.g.mapleader = " "
vim.g.loaded_matchparen = 1

-- Skip some remote provider loading
vim.g.loaded_python_provider = 0
vim.g.python_host_prog = '/usr/bin/python2'
vim.g.python3_host_prog = '/usr/bin/python'
vim.g.node_host_prog = '/usr/bin/neovim-node-host'

if vim.fn.executable('rg') == 1 then
    vim.g.rg_derive_root='true'
end

require'mappings'
require'plugins'
require'config'
