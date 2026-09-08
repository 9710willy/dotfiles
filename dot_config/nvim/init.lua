vim.g.mapleader = [[ ]]
vim.g.maplocalleader = [[,]]

vim.loader.enable()

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

require("settings.config")
require("plugins")
require("settings.lsp")
require("settings.mappings")
require("settings.autocmds")
