-- Hide the statusline on the start screen; enable it once real editing
-- starts. The module lua/statusline.lua renders it.
vim.o.laststatus = 0
vim.api.nvim_create_autocmd("User", {
	pattern = "ActuallyEditing",
	group = vim.api.nvim_create_augroup("statusline_enable", { clear = true }),
	once = true,
	callback = function()
		vim.o.laststatus = 3
		vim.o.statusline = "%!v:lua.require'statusline'.status()"
	end,
})
