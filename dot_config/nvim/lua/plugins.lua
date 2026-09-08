vim.pack.add(require("packages"), { confirm = false, load = true })
vim.cmd.packadd("matchit")

local map = vim.keymap.set

require("settings.colors")

require("flash").setup({
	modes = { search = { enabled = false } },
	exclude = {
		"NeogitStatus",
		"flash_prompt",
		function(win)
			return not vim.api.nvim_win_get_config(win).focusable
		end,
	},
})
map({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash treesitter" })
map("o", "r", function()
	require("flash").remote()
end, { desc = "Remote Flash" })
map({ "o", "x" }, "R", function()
	require("flash").treesitter_search()
end, { desc = "Treesitter search" })
map("c", "<C-f>", function()
	require("flash").toggle()
end, { desc = "Toggle Flash search" })

require("mini.sessions").setup({})

local starter = require("mini.starter")
starter.setup({
	header = "",
	footer = "",
	items = {
		{
			{ name = "new file", action = "ene | startinsert", section = "Actions" },
			{ name = "update plugins", action = "lua vim.pack.update()", section = "Actions" },
			{ name = "git", action = "Neogit", section = "Actions" },
			{ name = "quit", action = "qall", section = "Actions" },
		},
		starter.sections.recent_files(5, false),
		starter.sections.recent_files(5, true),
		starter.sections.sessions(5, true),
	},
	content_hooks = {
		starter.gen_hook.adding_bullet(""),
		starter.gen_hook.aligning("center", "center"),
	},
})

vim.api.nvim_set_hl(0, "MiniStarterSection", { link = "WhiteHover" })
vim.api.nvim_set_hl(0, "MiniStarterItemPrefix", { link = "Underlined" })
vim.api.nvim_set_hl(0, "MiniStarterItemBullet", { link = "Normal" })
vim.api.nvim_set_hl(0, "MiniStarterInactive", {
	fg = "#666666",
	bg = "#141414",
	italic = true,
	strikethrough = true,
})

require("mini.surround").setup({
	search_method = "cover_or_nearest",
	respect_selection_type = true,
	mappings = {
		add = "gza",
		delete = "gzd",
		find = "gzf",
		find_left = "gzF",
		highlight = "gzh",
		replace = "gzr",
		update_n_lines = "gzn",
	},
})
require("mini.align").setup({ mappings = { start = "ga", start_with_preview = "" } })
require("mini.ai").setup({ search_method = "cover_or_nearest" })
require("mini.bracketed").setup({})
require("mini.indentscope").setup({
	symbol = "│",
	options = { try_as_border = true },
	draw = { animation = require("mini.indentscope").gen_animation.none() },
})
require("mini.move").setup({})
require("mini.splitjoin").setup({ mappings = { toggle = "gJ" } })
require("mini.pairs").setup({
	mappings = {
		["("] = { action = "open", pair = "()", neigh_pattern = "[^\\][%s%)%]%}]" },
		["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\][%s%)%]%}]" },
		["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\][%s%)%]%}]" },
		[")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
		["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
		["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },
		['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%w][^%w]", register = { cr = false } },
		["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w][^%w]", register = { cr = false } },
		["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^%w][^%w]", register = { cr = false } },
	},
})
require("mini.operators").setup({})
require("mini.hipatterns").setup({
	highlighters = { hex_color = require("mini.hipatterns").gen_highlighter.hex_color() },
})

local clue = require("mini.clue")
clue.setup({
	triggers = {
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },
		{ mode = "i", keys = "<C-x>" },
		{ mode = "n", keys = "g" },
		{ mode = "x", keys = "g" },
		{ mode = "n", keys = "'" },
		{ mode = "n", keys = "`" },
		{ mode = "x", keys = "'" },
		{ mode = "x", keys = "`" },
		{ mode = "n", keys = '"' },
		{ mode = "x", keys = '"' },
		{ mode = "i", keys = "<C-r>" },
		{ mode = "c", keys = "<C-r>" },
		{ mode = "n", keys = "<C-w>" },
		{ mode = "n", keys = "z" },
		{ mode = "x", keys = "z" },
	},
	clues = {
		clue.gen_clues.builtin_completion(),
		clue.gen_clues.g(),
		clue.gen_clues.marks(),
		clue.gen_clues.registers(),
		clue.gen_clues.windows(),
		clue.gen_clues.z(),
	},
})

local pick = require("mini.pick")
local extra = require("mini.extra")
pick.setup({})
extra.setup({})
map({ "n", "x" }, "<C-a>", function()
	pick.builtin.buffers()
end, { desc = "Buffers" })
map({ "n", "x" }, "<C-d>", function()
	pick.builtin.files()
end, { desc = "Find files" })
map({ "n", "x" }, "<C-g>", function()
	pick.builtin.grep_live()
end, { desc = "Live grep" })
map("n", "<leader>c", function()
	extra.pickers.commands()
end, { desc = "Commands" })
map("n", "<leader>j", function()
	extra.pickers.list({ scope = "jump" })
end, { desc = "Jumplist" })
map("n", "<C-s>", function()
	extra.pickers.lsp({ scope = "document_symbol" })
end, { desc = "Document symbols" })
map("n", "<leader>xx", function()
	extra.pickers.diagnostic({ scope = "all" })
end, { desc = "Diagnostics" })
map("n", "<leader>xd", function()
	extra.pickers.diagnostic({ scope = "current" })
end, { desc = "Buffer diagnostics" })
map("n", "<leader>xs", function()
	extra.pickers.lsp({ scope = "document_symbol" })
end, { desc = "Document symbols" })
map("n", "<leader>xr", function()
	extra.pickers.lsp({ scope = "references" })
end, { desc = "References" })
map("n", "<leader>xl", function()
	extra.pickers.list({ scope = "location" })
end, { desc = "Location list" })
map("n", "<leader>xq", function()
	extra.pickers.list({ scope = "quickfix" })
end, { desc = "Quickfix list" })
map("n", "[q", "<cmd>silent! cprevious<cr>", { desc = "Previous quickfix item" })
map("n", "]q", "<cmd>silent! cnext<cr>", { desc = "Next quickfix item" })

require("settings.treesitter")
require("settings.neogen")

require("settings.dap_setup")
require("settings.dap")
local dap = require("dap")
local dapui = require("dapui")
dapui.setup({})
dap.listeners.after.event_initialized.dapui = function()
	dapui.open({})
end
dap.listeners.before.event_terminated.dapui = function()
	dapui.close({})
end
dap.listeners.before.event_exited.dapui = function()
	dapui.close({})
end
require("nvim-dap-virtual-text").setup({})

require("cmake-tools").setup({ cmake_always_use_terminal = true })
require("settings.gitsigns")
require("settings.neogit")
require("git-conflict").setup({})

map("n", "<leader>rs", "<cmd>IronRepl<cr>", { desc = "Open Iron REPL" })
map("n", "<leader>rr", "<cmd>IronRestart<cr>", { desc = "Restart Iron REPL" })
map("n", "<leader>rf", "<cmd>IronFocus<cr>", { desc = "Focus Iron REPL" })
map("n", "<leader>rh", "<cmd>IronHide<cr>", { desc = "Hide Iron REPL" })
require("iron.core").setup({
	config = {
		repl_open_cmd = require("iron.view").center("40%"),
		repl_definition = {
			python = require("iron.fts.python").ptipython,
			ocaml = require("iron.fts.ocaml").utop,
			lua = { command = "croissant" },
		},
		highlight = { italic = true },
	},
	keymaps = {
		send_motion = "<C-c>",
		visual_send = "<C-cr>",
		send_file = "<leader>rsf",
		send_line = "<C-cr>",
		send_mark = "<leader>rsm",
		mark_motion = "<leader>rmc",
		mark_visual = "<leader>rmc",
		remove_mark = "<leader>rmd",
		cr = "<leader>r<cr>",
		interrupt = "<leader>ri<leader>",
		exit = "<leader>rq",
		clear = "<leader>rC",
	},
})

local lint = require("lint")
lint.linters.chktex.ignore_exitcode = true
lint.linters_by_ft = {
	tex = { "chktex" },
	javascript = { "eslint_d" },
	typescript = { "eslint_d" },
	NeogitCommitMessage = { "gitlint" },
	c = { "flawfinder" },
	cpp = { "flawfinder" },
	lua = { "selene" },
	sh = { "shellcheck" },
	bash = { "shellcheck" },
	vim = { "vint" },
}
local lint_group = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
	group = lint_group,
	callback = function()
		lint.try_lint()
	end,
})
vim.api.nvim_create_autocmd("BufWritePost", {
	group = lint_group,
	pattern = { ".github/**/*.yaml", ".github/**/*.yml" },
	callback = function()
		lint.try_lint("actionlint")
	end,
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "yapf" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		javascript = { "eslint_d", "prettierd" },
		typescript = { "eslint_d", "prettierd" },
		rust = { "rustfmt" },
		bash = { "shfmt", "shellcheck" },
		zsh = { "shfmt" },
		sh = { "shfmt", "shellcheck" },
		toml = { "taplo" },
		["_"] = { "trim_whitespace" },
	},
})
map({ "n", "x" }, "<leader>f", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

require("venv-selector").setup({ options = { picker = "mini-pick" } })
map("n", "<leader>pv", "<cmd>VenvSelect<cr>", { desc = "Select virtualenv" })

map("n", "<leader>i", function()
	require("rulebook").ignoreRule()
end, { desc = "Ignore lint rule" })
map("n", "<leader>l", function()
	require("rulebook").lookupRule()
end, { desc = "Look up lint rule" })

require("spectre").setup({ live_update = true, is_insert_mode = true })
map("n", "<leader>S", function()
	require("spectre").toggle()
end, { desc = "Search and replace" })
map("n", "<leader>sw", function()
	require("spectre").open_visual({ select_word = true })
end, { desc = "Search current word" })
map("x", "<leader>sw", function()
	require("spectre").open_visual()
end, { desc = "Search selection" })
map("n", "<leader>sp", function()
	require("spectre").open_file_search({ select_word = true })
end, { desc = "Search current file" })

require("gitlinker").setup({})
map({ "n", "x" }, "<leader>gy", "<cmd>GitLink<cr>", { desc = "Copy git link" })
map({ "n", "x" }, "<leader>gY", "<cmd>GitLink!<cr>", { desc = "Open git link" })
map({ "n", "x" }, "<leader>gB", "<cmd>GitLink blame<cr>", { desc = "Copy blame link" })

local refactoring = require("refactoring")
refactoring.setup({})
map("x", "<leader>re", function()
	refactoring.refactor("Extract Function")
end, { desc = "Extract function" })
map("x", "<leader>rf", function()
	refactoring.refactor("Extract Function To File")
end, { desc = "Extract to file" })
map("x", "<leader>rv", function()
	refactoring.refactor("Extract Variable")
end, { desc = "Extract variable" })
map("n", "<leader>rI", function()
	refactoring.refactor("Inline Function")
end, { desc = "Inline function" })
map({ "n", "x" }, "<leader>ri", function()
	refactoring.refactor("Inline Variable")
end, { desc = "Inline variable" })
map("n", "<leader>rb", function()
	refactoring.refactor("Extract Block")
end, { desc = "Extract block" })
map("n", "<leader>rB", function()
	refactoring.refactor("Extract Block To File")
end, { desc = "Extract block to file" })
map("n", "<leader>rp", function()
	refactoring.debug.printf({ below = true })
end, { desc = "Debug print" })
map("n", "<leader>rc", function()
	refactoring.debug.cleanup({})
end, { desc = "Debug cleanup" })

local harpoon = require("harpoon")
harpoon:setup()
map("n", "<leader>a", function()
	harpoon:list():add()
end, { desc = "Harpoon add" })
map("n", "<leader>h", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon menu" })
for index = 1, 4 do
	map("n", "<leader>" .. index, function()
		harpoon:list():select(index)
	end, { desc = "Harpoon " .. index })
end
