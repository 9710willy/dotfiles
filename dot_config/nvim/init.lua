vim.g.mapleader = [[ ]]
vim.g.maplocalleader = [[,]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end

vim.loader.enable()
vim.opt.runtimepath:prepend(lazypath)

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

require("lazy").setup("plugins", {
	defaults = { lazy = true },
	-- no plugin here needs luarocks; disabling stops the hererocks
	-- checkhealth errors
	rocks = { enabled = false },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

require("settings.mappings")
require("settings.autocmds")
require("settings.config")
-- settings.colors already runs as the gruvbox plugin config (lazy = false)
