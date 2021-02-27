local keymap = require'utils/keymap'

local nmap = keymap.nmap
local imap = keymap.imap
local cmap = keymap.cmap
local vmap = keymap.vmap
local xmap = keymap.xmap
local omap = keymap.omap
local tmap = keymap.tmap

nmap('<leader>pv', ':Sex!<CR>')
nmap('<leader>u', ':UndotreeShow<CR>')

-- vim TODO
nmap('<leader>tu' ,'<Plug>BujoChecknormal')
nmap('<leader>th' ,'<Plug>BujoAddnormal')

nmap('<leader>h', ':wincmd h<CR>')
nmap('<leader>j', ':wincmd j<CR>')
nmap('<leader>k', ':wincmd k<CR>')
nmap('<leader>l', ':wincmd l<CR>')

-- Use <Tab> and <S-Tab> to navigate through popup menu
imap('<S-Tab>', 'pumvisible() ? "\\<C-p>" : "\\<Tab>"', {expr = true, noremap = true} )
imap('<Tab>', 'pumvisible() ? "\\<C-n>" : "\\<Tab>"', {expr = true, noremap = true})

-- Telescope
nmap('<leader>ps', ':lua require("telescope.builtin").grep_string({ search = vim.fn.input("Grep For > ")})<CR>')
nmap('<C-p>', ':lua require("telescope.builtin").git_files()<CR>')
nmap('<leader>pf', ':lua require("telescope.builtin").find_files()<CR>')

nmap('<leader>pw', ':lua require("telescope.builtin").grep_string { search = vim.fn.expand("<cword>") }<CR>')
nmap('<leader>pb', ':lua require("telescope.builtin").buffers()<CR>')
nmap('<leader>vh', ':lua require("telescope.builtin").help_tags()<CR>')
