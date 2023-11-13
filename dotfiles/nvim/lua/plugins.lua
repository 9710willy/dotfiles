return {
	{
		"ojroques/nvim-bufdel",
		cmd = "BufDel",
		opts = {},
	},
	{
		"folke/which-key.nvim",
		opts = {},
		event = "BufReadPost",
	},
	{ "chaoren/vim-wordmotion", event = "VeryLazy" },
	{
		"ggandor/leap.nvim",
		event = "VeryLazy",
		dependencies = "tpope/vim-repeat",
		config = function()
			local map = vim.api.nvim_set_keymap
			-- 2-character Sneak (default)
			local opts = { noremap = false }
			map("n", "z", "<Plug>(leap-forward-x)", opts)
			map("n", "Z", "<Plug>(leap-backward-x)", opts)

			-- visual-mode
			map("x", "z", "<Plug>(leap-forward-x)", opts)
			map("x", "Z", "<Plug>(leap-backward-x)", opts)

			-- operator-pending-mode
			map("o", "z", "<Plug>(leap-forward-x)", opts)
			map("o", "Z", "<Plug>(leap-backward-x)", opts)
		end,
	},
	{
		"ggandor/flit.nvim",
		opts = { labeled_modes = "nv" },
		event = "VeryLazy",
	},
	{ "Olical/vim-enmasse", cmd = "EnMasse" },
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
	},
	{
		"echasnovski/mini.nvim",
		version = false,
		event = "User ActuallyEditing",
		config = function()
			require("mini.surround").setup({ search_method = "cover_or_nearest" })
			require("mini.align").setup({ mappings = { start = "", start_with_preview = "g=" } })
			require("mini.ai").setup({ search_method = "cover_or_nearest" })
			require("mini.bracketed").setup({})
			require("mini.comment").setup({ options = { ignore_blank_line = true } })
			require("mini.indentscope").setup({
				symbol = "│",
				options = { try_as_border = true },
				draw = { animation = require("mini.indentscope").gen_animation.none() },
			})
			require("mini.move").setup({})
			require("mini.splitjoin").setup({ mappings = { toggle = "gJ" } })
		end,
	},
	{
		"windwp/nvim-autopairs",
		opts = {
			enable_check_bracket_line = false,
			ignored_next_char = "[%w%.]",
			fast_wrap = {},
		},
		event = "BufReadPost",
	},
	{
		"andymass/vim-matchup",
		init = function()
			require("config.matchup")
		end,
		event = "User ActuallyEditing",
	},
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			require("settings.colors")
		end,
		lazy = false,
	},
	"neovim/nvim-lspconfig",
	{
		"smjonas/inc-rename.nvim",
		opts = {},
		event = "BufReadPost",
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
	},
	"p00f/clangd_extensions.nvim",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
			"lukas-reineke/cmp-under-comparator",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"doxnit/cmp-luasnip-choice",
		},
		config = function()
			require("settings.cmp")
		end,
		event = "InsertEnter",
	},
	{
		"mfussenegger/nvim-dap",
		init = function()
			require("settings.dap_setup")
		end,
		config = function()
			require("settings.dap")
		end,
		dependencies = "jbyuki/one-small-step-for-vimkind",
		cmd = { "BreakpointToggle", "Debug", "DapREPL" },
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = "nvim-dap",
		opts = {},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		init = function()
			vim.g.neo_tree_remove_legacy_commands = true
		end,
		cmd = "Neotree",
		event = "User EditingDirectory",
		config = function()
			require("settings.neotree")
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
	},
	"folke/neodev.nvim",
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"RRethy/nvim-treesitter-textsubjects",
			"RRethy/nvim-treesitter-endwise",
		},
		build = ":TSUpdate",
		event = "VeryLazy",
		config = function()
			require("settings.treesitter")
		end,
	},
	{
		"danymat/neogen",
		dependencies = "nvim-treesitter",
		config = function()
			require("config.neogen")
		end,
		keys = { "<localleader>d", "<localleader>df", "<localleader>dc" },
	},
	"L3MON4D3/LuaSnip",
	{ "rafamadriz/friendly-snippets", lazy = false },
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"andymass/vim-matchup",
		init = function()
			require("settings.matchup")
		end,
		event = "User ActuallyEditing",
	},
	{ "romainl/vim-cool", event = "VeryLazy" },
	{ "wellle/targets.vim", event = "VeryLazy" },
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		init = function()
			vim.g.undotree_SetFocusWhenToggle = 1
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("settings.gitsigns")
		end,
		event = "VeryLazy",
	},
	{
		"sindrets/diffview.nvim",
		dependencies = "nvim-lua/plenary.nvim",
	},
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
		config = function()
			require("settings.neogit")
		end,
	},
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		opts = {},
		event = "BufReadPost",
	},
	{
		"lewis6991/hover.nvim",
		event = "BufReadPost",
		config = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
				end,
			})

			vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
			vim.keymap.set("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })
		end,
	},
	{
		"DNLHC/glance.nvim",
		cmd = "Glance",
		config = function()
			require("glance").setup({
				detached = true,
				border = { enable = true, top_char = "─", bottom_char = "─" },
				theme = { mode = "brighten" },
				indent_lines = { icon = "│" },
				winbar = { enable = true },
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/popup.nvim",
			"nvim-lua/plenary.nvim",
			"telescope-fzf-native.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		init = function()
			require("settings.telescope_setup")
		end,
		config = function()
			require("settings.telescope")
		end,
		cmd = "Telescope",
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
	"crispgm/telescope-heading.nvim",
	"nvim-telescope/telescope-file-browser.nvim",
	{
		"stevearc/aerial.nvim",
		opts = {
			backends = { "lsp", "treesitter", "markdown", "man" },
			on_attach = function(bufnr)
				vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
				vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
			end,
		},
		cmd = { "AerialOpen", "AerialToggle" },
	},
	{
		"folke/todo-comments.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		event = "BufReadPost",
		opts = {},
	},
	{
		"ethanholz/nvim-lastplace",
		config = function()
			require("nvim-lastplace").setup({})
			vim.api.nvim_exec_autocmds("BufWinEnter", { group = "NvimLastplace" })
		end,
		event = "User ActuallyEditing",
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			require("toggleterm").setup({ open_mapping = [[<c-\>]] })
		end,
		keys = [[<c-\>/]],
	},
	{
		"beauwilliams/focus.nvim",
		config = function()
			require("focus").setup({ excluded_filetypes = { "toggleterm", "TelescopePrompt" }, signcolumn = false })
		end,
		event = "VeryLazy",
	},
	{
		"hkupty/iron.nvim",
		cmd = { "IronRepl", "IronFocus" },
		init = function()
			vim.keymap.set("n", "<leader>rs", "<cmd>IronRepl<cr>")
			vim.keymap.set("n", "<leader>rr", "<cmd>IronRestart<cr>")
			vim.keymap.set("n", "<leader>rf", "<cmd>IronFocus<cr>")
			vim.keymap.set("n", "<leader>rh", "<cmd>IronHide<cr>")
		end,
		dependencies = "which-key.nvim",
		config = function()
			require("iron.core").setup({
				config = {
					repl_open_cmd = require("iron.view").right("40%"),
					repl_definition = {
						python = require("iron.fts.python").ptipython,
						ocaml = require("iron.fts.ocaml").utop,
						lua = { command = "croissant" },
					},
					highlight = { italic = true },
				},
				keymaps = {
					send_motion = "<c-c>",
					visual_send = "<c-cr>",
					send_file = "<leader>rsf",
					send_line = "<c-cr>",
					send_mark = "<leader>rsm",
					mark_motion = "<leader>rmc",
					mark_visual = "<leader>rmc",
					remove_mark = "<leader>rmd",
					cr = "<leader>r<cr>",
					interrupt = "<leader>ri<leader>",
					exit = "<leader>rq",
					clear = "<leader>rc",
				},
			})
		end,
	},
	{
		"utilyre/barbecue.nvim",
		event = "User ActuallyEditing",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			create_autocmd = false,
			attach_navic = false,
			show_modified = true,
			exclude_filetypes = { "netrw", "toggleterm", "NeogitCommitMessage" },
			custom_section = function()
				-- Copied from @akinsho's config
				local error_icon = "" -- '✗'
				local warning_icon = ""
				local info_icon = "" --  
				local hint_icon = "⚑" --  ⚑
				local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
				local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
				local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
				local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
				local components = {}
				if errors > 0 then
					components[#components + 1] = { error_icon .. " " .. errors, "DiagnosticError" }
				end
				if warnings > 0 then
					components[#components + 1] =
						{ (#components > 0 and " " or "") .. warning_icon .. " " .. warnings, "DiagnosticWarning" }
				end
				if hints > 0 then
					components[#components + 1] =
						{ (#components > 0 and " " or "") .. hint_icon .. " " .. hints, "DiagnosticHint" }
				end
				if info > 0 then
					components[#components + 1] =
						{ (#components > 0 and " " or "") .. info_icon .. " " .. info, "DiagnosticInfo" }
				end
				return components
			end,
		},
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePre" },
		config = function()
			local lint = require("lint")
			local chktex = lint.linters.chktex
			-- NOTE: chktex returns non-zero exit codes if there are any warnings or errors reported
			chktex.ignore_exitcode = true
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
				zsh = { "shellcheck" },
				vim = { "vint" },
			}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				-- Customize or remove this keymap to your liking
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "yapf" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				javascript = { "eslint_d", "prettierd" },
				typescript = { "eslint_d", "prettierd" },
				rust = { "rustfmt" },
				bash = { "shfmt", "shellcheck" },
				zsh = { "shfmt", "shellcheck" },
				sh = { "shfmt", "shellcheck" },
				toml = { "taplo" },
				["_"] = { "trim_whitespace" },
			},
		},
	},
	{
		"folke/noice.nvim",
		config = function()
			require("noice").setup({
				views = { mini = { lang = "markdown" } },
				routes = {
					{
						filter = {
							event = "msg_show",
							kind = "",
							find = "written",
						},
						opts = { skip = true },
					},
					{
						filter = {
							event = "lsp",
							kind = "progress",
							find = "null-l",
						},
						opts = { skip = true, stop = true },
					},
					{
						view = "notify",
						filter = { event = "msg_showmode" },
					},
				},
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					inc_rename = true,
					lsp_doc_border = true,
				},
			})
		end,
		dependencies = { "MunifTanjim/nui.nvim" },
		event = "VeryLazy",
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = "neovim/nvim-lspconfig",
		opts = { lazy_update_context = true },
	},
}
