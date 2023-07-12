-- Keybindings
local silent = { silent = true, noremap = true }

vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", silent)

-- Quit, close buffers, etc.
vim.keymap.set("n", "<leader>q", "<cmd>qa<cr>", silent)
vim.keymap.set("n", "<leader>x", "<cmd>x!<cr>", silent)
vim.keymap.set("n", "<leader>d", "<cmd>BufDel<cr>", { silent = true, nowait = true, noremap = true })

-- Save buffer
vim.keymap.set('i', '<c-s>', '<esc><cmd>w<cr>a', silent)
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', silent)

-- Version control
vim.keymap.set("n", "gs", "<cmd>Neogit<cr>", silent)

-- Yank to clipboard
vim.keymap.set("n", "y+", "<cmd>set opfunc=util#clipboard_yank<cr>g@", silent)
vim.keymap.set("v", "y+", "<cmd>set opfunc=util#clipboard_yank<cr>g@", silent)

-- wincmds
vim.keymap.set("n", "<leader>h", ":wincmd h<CR>", silent)
vim.keymap.set("n", "<leader>j", ":wincmd j<CR>", silent)
vim.keymap.set("n", "<leader>k", ":wincmd k<CR>", silent)
vim.keymap.set("n", "<leader>l", ":wincmd l<CR>", silent)

-- Tab movement
vim.keymap.set("n", "<c-Left>", "<cmd>tabpre<cr>", silent)
vim.keymap.set("n", "<c-Right>", "<cmd>tabnext<cr>", silent)

-- Telescope
--nmap("<leader>ps", ':lua require("telescope.builtin").grep_string({ search = vim.fn.input("Grep For > ")})<CR>')
--nmap("<C-p>", ':lua require("telescope.builtin").git_files()<CR>')
--nmap("<leader>pf", ':lua require("telescope.builtin").find_files()<CR>')

--nmap("<leader>pw", ':lua require("telescope.builtin").grep_string { search = vim.fn.expand("<cword>") }<CR>')
--nmap("<leader>pb", ':lua require("telescope.builtin").buffers()<CR>')
--nmap("<leader>vh", ':lua require("telescope.builtin").help_tags()<CR>')
