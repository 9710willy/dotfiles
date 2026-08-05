local opts = { silent = true }
vim.keymap.set('n', '<c-a>', '<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>', opts)
vim.keymap.set('n', '<c-d>', '<cmd>Telescope find_files theme=get_dropdown<cr>', opts)
vim.keymap.set('n', '<c-g>', '<cmd>Telescope live_grep theme=get_dropdown<cr>', opts)
vim.keymap.set('n', '<c-p>', '<cmd>Telescope commands theme=get_dropdown<cr>', opts)
vim.keymap.set('n', '<c-s>', '<cmd>Telescope aerial theme=get_dropdown<cr>', opts)
vim.keymap.set('n', '<Space-j>', '<cmd>Telescope jumplist theme=get_dropdown<cr>', opts)
