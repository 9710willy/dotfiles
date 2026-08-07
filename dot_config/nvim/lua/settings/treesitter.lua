-- nvim-treesitter "main" branch (rewrite). The old module system
-- (nvim-treesitter.configs) is gone. Highlighting and folds now use
-- core Neovim APIs; this file wires them up per buffer.
local ts = require("nvim-treesitter")

local max_filesize = 100 * 1024 -- 100 KB; skip treesitter in large files
local max_lines = 5000

local function too_big(buf)
	if vim.api.nvim_buf_line_count(buf) > max_lines then
		return true
	end
	local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
	return ok and stats and stats.size > max_filesize
end

local install_attempted = {}

-- languages nvim-treesitter can install; get_lang() falls back to the
-- raw filetype, so plugin buffers (fidget, noice, ...) would otherwise
-- trigger doomed installs that warn on every session
local installable
local function can_install(lang)
	if not installable then
		installable = {}
		for _, l in ipairs(ts.get_available()) do
			installable[l] = true
		end
	end
	return installable[lang]
end

local function enable_treesitter(buf, ft)
	local lang = vim.treesitter.language.get_lang(ft)
	if not lang or too_big(buf) then
		return
	end

	if vim.treesitter.language.add(lang) then
		vim.treesitter.start(buf, lang)
		return
	end

	-- Parser missing: install it on demand (old `auto_install = true`).
	-- Needs the tree-sitter CLI; skip quietly when it is not available.
	if install_attempted[lang] or not can_install(lang) or vim.fn.executable("tree-sitter") == 0 then
		return
	end
	install_attempted[lang] = true
	-- ~/bin/cc shadows the system C compiler in PATH (it is not a
	-- compiler), and "tree-sitter build" resolves $CC, then "cc". Point
	-- it at the real compiler for the duration of the build.
	local prev_cc = vim.env.CC
	vim.env.CC = "/usr/bin/cc"
	ts.install({ lang }):await(function()
		vim.env.CC = prev_cc
		if vim.api.nvim_buf_is_valid(buf) and vim.treesitter.language.add(lang) then
			vim.treesitter.start(buf, lang)
		end
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
	callback = function(args)
		enable_treesitter(args.buf, args.match)
	end,
})

-- This file loads on BufReadPost/BufNewFile, so FileType may already have
-- fired for the first buffers. Cover them here.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
		enable_treesitter(buf, vim.bo[buf].filetype)
	end
end

-- Incremental node selection: parity with the old nvim-treesitter
-- incremental_selection module (<C-Space> grow, <BS> shrink). Core
-- 0.12 ships an/in textobjects for this, but mini.ai shadows them
-- with its own an/in ("around/inside next"), so wire it explicitly
-- with public API only.
local sel_stack = {}

local function select_range(node)
	local ok, srow, scol, erow, ecol = pcall(function()
		return node:range()
	end)
	if not ok then
		return false
	end
	local last = vim.api.nvim_buf_line_count(0)
	if erow >= last then
		erow, ecol = last - 1, #vim.fn.getline(last)
	elseif ecol == 0 then
		erow = math.max(erow - 1, srow)
		ecol = #vim.fn.getline(erow + 1)
	end
	if vim.fn.mode():match("^[vV\22]") then
		vim.cmd("normal! \27")
	end
	vim.fn.setpos("'<", { 0, srow + 1, scol + 1, 0 })
	vim.fn.setpos("'>", { 0, erow + 1, math.max(ecol, 1), 0 })
	vim.cmd("normal! gv")
	if vim.fn.mode() ~= "v" then
		vim.cmd("normal! v")
	end
	return true
end

local function visual_range()
	local vpos = vim.fn.getpos("v")
	local cpos = vim.fn.getpos(".")
	local srow, scol = vpos[2] - 1, vpos[3] - 1
	local erow, ecol = cpos[2] - 1, cpos[3] - 1
	if srow > erow or (srow == erow and scol > ecol) then
		srow, scol, erow, ecol = erow, ecol, srow, scol
	end
	return srow, scol, erow, ecol + 1
end

local function init_selection()
	local node = vim.treesitter.get_node()
	if not node then
		return
	end
	sel_stack[vim.api.nvim_get_current_buf()] = { node }
	select_range(node)
end

local function expand_selection()
	local buf = vim.api.nvim_get_current_buf()
	local srow, scol, erow, ecol = visual_range()
	local parser = vim.treesitter.get_parser(buf, nil, { error = false })
	if not parser then
		return
	end
	local tree = parser:parse()[1]
	if not tree then
		return
	end
	local node = tree:root():named_descendant_for_range(srow, scol, erow, ecol)
	-- climb until the node is strictly larger than the selection
	while node do
		local nsr, nsc, ner, nec = node:range()
		local same = nsr == srow and nsc == scol and ner == erow and nec == ecol
		local contains = (nsr < srow or (nsr == srow and nsc <= scol)) and (ner > erow or (ner == erow and nec >= ecol))
		if contains and not same then
			break
		end
		node = node:parent()
	end
	if not node then
		return
	end
	local stack = sel_stack[buf] or {}
	stack[#stack + 1] = node
	sel_stack[buf] = stack
	select_range(node)
end

local function shrink_selection()
	local buf = vim.api.nvim_get_current_buf()
	local stack = sel_stack[buf]
	if not stack or #stack <= 1 then
		return
	end
	stack[#stack] = nil
	if not select_range(stack[#stack]) then
		sel_stack[buf] = nil
	end
end

vim.keymap.set("n", "<C-Space>", init_selection, { desc = "Treesitter: start selection" })
vim.keymap.set("x", "<C-Space>", expand_selection, { desc = "Treesitter: expand selection" })
vim.keymap.set("x", "<BS>", shrink_selection, { desc = "Treesitter: shrink selection" })

-- Enable autotag (windwp/nvim-ts-autotag)
require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = true,
	},
})

-- Treesitter-based folding (faster than syntax)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
