local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("misc_autocmds", { clear = true })

autocmd("BufWinEnter", { group = group, command = "checktime" })
autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.hl.on_yank()
	end,
})
autocmd("FileType", { group = group, pattern = "qf", command = "setlocal nobuflisted" })
autocmd("BufReadPost", {
	group = group,
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
