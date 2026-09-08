local ts = require("nvim-treesitter")
local max_filesize = 100 * 1024
local max_lines = 5000
local install_attempted = {}
local installable

local function too_big(buf)
	if vim.api.nvim_buf_line_count(buf) > max_lines then
		return true
	end
	local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
	return ok and stats and stats.size > max_filesize
end

local function can_install(lang)
	if not installable then
		installable = {}
		for _, available in ipairs(ts.get_available()) do
			installable[available] = true
		end
	end
	return installable[lang]
end

local function enable(buf, filetype)
	local lang = vim.treesitter.language.get_lang(filetype)
	if not lang or too_big(buf) then
		return
	end

	if vim.treesitter.language.add(lang) then
		vim.treesitter.start(buf, lang)
		return
	end

	if install_attempted[lang] or not can_install(lang) or vim.fn.executable("tree-sitter") == 0 then
		return
	end

	install_attempted[lang] = true
	ts.install({ lang }):await(function()
		if vim.api.nvim_buf_is_valid(buf) and vim.treesitter.language.add(lang) then
			vim.treesitter.start(buf, lang)
		end
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
	callback = function(args)
		enable(args.buf, args.match)
	end,
})

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
		enable(buf, vim.bo[buf].filetype)
	end
end

vim.keymap.set({ "n", "x" }, "<C-Space>", function()
	vim.treesitter.select("parent")
end, { desc = "Select parent syntax node" })
vim.keymap.set("x", "<BS>", function()
	vim.treesitter.select("child")
end, { desc = "Select child syntax node" })

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = true,
	},
})

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
