vim.o.background = "dark"
vim.o.termguicolors = true
-- Restores the old g:gruvbox_contrast_dark = "hard" intent; must run
-- before :colorscheme.
require("gruvbox").setup({ contrast = "hard" })
vim.cmd([[colorscheme gruvbox]])
