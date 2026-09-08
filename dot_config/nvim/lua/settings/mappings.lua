local map = vim.keymap.set

map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit" })
map("n", "<leader>x", "<cmd>x!<cr>", { desc = "Save and quit" })
map("n", "<leader>d", "<cmd>bdelete<cr>", { desc = "Delete buffer", nowait = true })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "File explorer" })
map("n", "<leader>tt", "<cmd>botright new | terminal<cr>", { desc = "Terminal" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search" })

map("i", "<C-s>", "<Esc><cmd>write<cr>a", { desc = "Save" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>g", "<cmd>Neogit<cr>", { desc = "Neogit" })

map("i", "<C-Space>", vim.lsp.completion.get, { desc = "Complete" })

map("n", "y+", "<cmd>set opfunc=util#clipboard_yank<cr>g@", { desc = "Yank to clipboard" })
map("v", "y+", "<cmd>set opfunc=util#clipboard_yank<cr>g@", { desc = "Yank to clipboard" })

map("n", "<C-h>", "<C-w>h", { desc = "Move to window at left" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to window at right" })
map("n", "<C-Left>", "<cmd>tabprevious<cr>", { desc = "Move to tab at left" })
map("n", "<C-Right>", "<cmd>tabnext<cr>", { desc = "Move to tab at right" })

for _, key in ipairs({ "j", "k" }) do
	map("n", key, function()
		if vim.v.count > 1 then
			return [[m']] .. vim.v.count .. key
		end
		return key
	end, { expr = true, silent = true })
end

map("n", "<leader>s", function()
	require("mini.sessions").write(vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), {})
end, { desc = "Write current session" })
