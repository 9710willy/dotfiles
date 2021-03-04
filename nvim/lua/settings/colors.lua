local function highlight(key, value)
  vim.cmd(string.format('highlight %s guifg=%s', key, value))
end

vim.o.background = 'dark'
if vim.fn.has("+termguicolors") == 1 then
    vim.cmd('set t_8f=\\[38;2;%lu;%lu;%lum')
    vim.cmd('set t_8b=\\[48;2;%lu;%lu;%lum')
end
vim.o.termguicolors=true
vim.g.gruvbox_contrast_dark = 'hard'
vim.g.gruvbox_invert_selection = '0'

vim.cmd('colorscheme gruvbox')
vim.cmd('highlight ColorColumn ctermbg=0 guibg=grey')
vim.cmd('highlight Normal guibg=none')
highlight('LineNr', '#5eacd3')
highlight('netrwDir', '#5eacd3')
highlight('qfFileName', '#aed75f')
highlight('TelescopeBorder', '#5eacd')
