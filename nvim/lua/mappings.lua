local keymap = require'utils/keymap'

local nmap = keymap.nmap

nmap('<leader>pv', ':Sex!<CR>')
nmap('<leader>u', ':UndotreeShow<CR>')

-- vim TODO
nmap('<leader>tu' ,'<Plug>BujoChecknormal')
nmap('<leader>th' ,'<Plug>BujoAddnormal')

-- wincmds
nmap('<leader>h', ':wincmd h<CR>')
nmap('<leader>j', ':wincmd j<CR>')
nmap('<leader>k', ':wincmd k<CR>')
nmap('<leader>l', ':wincmd l<CR>')

-- Telescope
nmap('<leader>ps', ':lua require("telescope.builtin").grep_string({ search = vim.fn.input("Grep For > ")})<CR>')
nmap('<C-p>', ':lua require("telescope.builtin").git_files()<CR>')
nmap('<leader>pf', ':lua require("telescope.builtin").find_files()<CR>')

nmap('<leader>pw', ':lua require("telescope.builtin").grep_string { search = vim.fn.expand("<cword>") }<CR>')
nmap('<leader>pb', ':lua require("telescope.builtin").buffers()<CR>')
nmap('<leader>vh', ':lua require("telescope.builtin").help_tags()<CR>')

-- Git
nmap('<leader>gs', ':Git<CR>')


