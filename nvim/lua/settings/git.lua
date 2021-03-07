local keymap = require'utils/keymap'

local nmap = keymap.nmap

nmap('<leader>gc', ':GBranches<CR>')
nmap('<leader>ga', ':Git fetch --all<CR>')
nmap('<leader>grum', ':Git rebase upstream/master<CR>')
nmap('<leader>grom', ':Git rebase origin/master<CR>')

nmap('<leader>gj', ':diffget //3<CR>')
nmap('<leader>gf', ':diffget //2<CR>')
