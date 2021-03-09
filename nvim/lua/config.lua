local function set(key, value)
    if value == true or value == nil then
  vim.cmd(string.format('set %s', key))
    elseif value == false then
  vim.cmd(string.format('set no%s', key))
    else
  vim.cmd(string.format('set %s=%s', key, value))
    end
end

vim.cmd('set guicursor=')
set 'relativenumber'
set 'nohlsearch'
set 'hidden'
set 'noerrorbells'
set ('tabstop', 4)
set ('softtabstop', 4)
set ('shiftwidth', 4)
set 'expandtab'
--set 'smartindent'
set 'number'
set 'nowrap'
set 'noswapfile'
set 'nobackup'
set ('undodir', '~/.vim/undodir')
set 'undofile'
set 'incsearch'
set 'termguicolors'
set ('scrolloff', 8)
set ('signcolumn','yes')
vim.cmd('set isfname+=@-@')

-- Give more space for displaying messages.
set ('cmdheight', 2)

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
set ('updatetime', 500)

-- Don't pass messages to |ins-completion-menu|.
vim.cmd('set shortmess+=c')
set ('completeopt', 'menuone,noinsert,noselect')

set('colorcolumn', "100")

--netrw
vim.g.netrw_browse_split = 2
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.localrmdir = 'rm -r'
