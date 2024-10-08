--# selene: allow(mixed_table)
return {
	{
		"ojroques/nvim-bufdel",
		cmd = "BufDel",
		opts = {},
	},
	{ "chaoren/vim-wordmotion", event = "VeryLazy" },
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = { search = { enabled = false } },
			exclude = {
				"NeogitStatus",
				"notify",
				"cmp_menu",
				"noice",
				"flash_prompt",
				function(win)
					return not vim.api.nvim_win_get_config(win).focusable
				end,
			},
		},
		keys = {
			{
				"z",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"Z",
				mode = { "n", "o", "x" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-F>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
	{ "Olical/vim-enmasse", cmd = "EnMasse" },
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
	},
	{
		"echasnovski/mini.nvim",
        version = false,
    event = { 'BufReadPost', 'BufNewFile' },
    init = function()
      require('mini.sessions').setup {}
      vim.api.nvim_set_hl(0, 'MiniStarterSection', { link = 'WhiteHover' })
      vim.api.nvim_set_hl(0, 'MiniStarterItemPrefix', { link = 'Underlined' })
      vim.api.nvim_set_hl(0, 'MiniStarterItemBullet', { link = 'Normal' })
      vim.api.nvim_set_hl(
        0,
        'MiniStarterInactive',
        { fg = '#666666', bg = '#141414', italic = true, strikethrough = true }
      )
      local starter = require 'mini.starter'
      starter.setup {
        header = '',
        footer = '',
        items = {
          {
            { name = 'new file', action = 'ene | startinsert', section = 'Actions' },
            { name = 'update plugins', action = 'Lazy sync', section = 'Actions' },
            { name = 'git', action = 'Neogit', section = 'Actions' },
            { name = 'time startup', action = 'Lazy profile', section = 'Actions' },
            { name = 'quit', action = 'qall', section = 'Actions' },
          },
          starter.sections.recent_files(5, false),
          starter.sections.recent_files(5, true),
          starter.sections.sessions(5, true),
        },
        content_hooks = {
          -- require('utils').icon_hook,
          starter.gen_hook.adding_bullet '',
          starter.gen_hook.aligning('center', 'center'),
        },
      }
    end,
		config = function()
      require('mini.surround').setup { search_method = 'cover_or_nearest', respect_selection_type = true }
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
            require('mini.pairs').setup {
        mappings = {
          -- Prevents the action if the cursor is just before any character or next to a "\".
          ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\][%s%)%]%}]' },
          ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\][%s%)%]%}]' },
          ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\][%s%)%]%}]' },
          -- This is default (prevents the action if the cursor is just next to a "\").
          [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
          [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
          ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
          -- Prevents the action if the cursor is just before or next to any character.
          ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^%w][^%w]', register = { cr = false } },
          ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%w][^%w]', register = { cr = false } },
          ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^%w][^%w]', register = { cr = false } },
        },
      }
      require('mini.operators').setup {}
      require('mini.hipatterns').setup {
        highlighters = { hex_color = require('mini.hipatterns').gen_highlighter.hex_color() },
      }
      local miniclue = require 'mini.clue'
      miniclue.setup {
        triggers = {
          -- Leader triggers
          { mode = 'n', keys = '<Leader>' },
          { mode = 'x', keys = '<Leader>' },

          -- Built-in completion
          { mode = 'i', keys = '<C-x>' },

          -- `g` key
          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },

          -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },

          -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },

          -- Window commands
          { mode = 'n', keys = '<C-w>' },

          -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },
        },

        clues = {
          -- Enhance this by adding descriptions for <Leader> mapping groups
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
      }
		end,
	},
	{
		"andymass/vim-matchup",
		config = function()
			require("settings.matchup")
		end,
    event = { 'BufReadPost', 'BufNewFile' },
	},
	{ "romainl/vim-cool", event = "VeryLazy" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'nvim-telescope/telescope-ui-select.nvim',
      'debugloop/telescope-undo.nvim',
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
		"ellisonleao/gruvbox.nvim",
		config = function()
			require("settings.colors")
		end,
		lazy = false,
	},
	"neovim/nvim-lspconfig",
	"nvim-tree/nvim-web-devicons",
	{
		"smjonas/inc-rename.nvim",
		opts = {},
    event = { 'BufReadPost', 'BufNewFile' },
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
	},
	"p00f/clangd_extensions.nvim",
  {
  'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-refactor',
      'RRethy/nvim-treesitter-textsubjects',
      'RRethy/nvim-treesitter-endwise',
      'windwp/nvim-ts-autotag',
    },
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require 'settings.treesitter'
    end,
  },
	{
		"danymat/neogen",
		dependencies = "nvim-treesitter",
		config = function()
			require("settings.neogen")
		end,
		keys = { "<localleader>d", "<localleader>df", "<localleader>dc" },
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"lukas-reineke/cmp-under-comparator",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
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
		dependencies = {
			"jbyuki/one-small-step-for-vimkind",
      "nvim-neotest/nvim-nio",
			{
				"rcarriga/nvim-dap-ui",
				opts = {},
				config = function(_, opts)
					local dap = require("dap")
					local dapui = require("dapui")
					dapui.setup(opts)
					dap.listeners.after.event_initialized["dapui_config"] = function()
						dapui.open({})
					end
					dap.listeners.before.event_terminated["dapui_config"] = function()
						dapui.close({})
					end
					dap.listeners.before.event_exited["dapui_config"] = function()
						dapui.close({})
					end
				end,
			},
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = {},
			},
		},
		cmd = { "BreakpointToggle", "Debug", "DapREPL" },
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
	{ "Civitasv/cmake-tools.nvim", lazy = true, opts = { cmake_always_use_terminal = true } },
  { 'folke/neodev.nvim', opts = { lspconfig = false, library = { plugins = { 'nvim-dap-ui' }, types = true } } },

	{
		"lewis6991/gitsigns.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("settings.gitsigns")
		end,
		event = "VeryLazy",
	},
	{
		"NeogitOrg/neogit",
    branch = 'master',
		cmd = "Neogit",
		config = function()
			require("settings.neogit")
		end,
    dependencies = {
      {
        'sindrets/diffview.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
      },
      'telescope.nvim',
    },
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
			require("hover").setup{
				init = function()
					require("hover.providers.lsp")
          require 'hover.providers.dap'
				end,
			}

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
  { 'rafamadriz/friendly-snippets' },
  { 'garymjr/nvim-snippets', opts = { friendly_snippets = true } },
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
	{ "wellle/targets.vim", event = "VeryLazy" },
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
		"willothy/flatten.nvim",
		opts = {
			window = { open = "alternate" },
			post_open = function(_bufnr, winnr, _ft, is_blocking)
				if is_blocking then
					require("toggleterm").toggle(0)
				else
					vim.api.nvim_set_current_win(winnr)
				end
			end,
		},
		event = "TermOpen",
	},
	{
		"beauwilliams/focus.nvim",
		config = function()
			require("focus").setup({ excluded_filetypes = { "toggleterm", "TelescopePrompt" }, signcolumn = false })
		end,
		event = "VeryLazy",
	},
	{
    'vigemus/iron.nvim',
		cmd = { "IronRepl", "IronFocus" },
		init = function()
      vim.keymap.set('n', '<leader>rs', '<cmd>IronRepl<cr>', {desc = "Open Iron REPL"})
      vim.keymap.set('n', '<leader>rr', '<cmd>IronRestart<cr>', {desc = "Restart Iron REPL"})
      vim.keymap.set('n', '<leader>rf', '<cmd>IronFocus<cr>', {desc = "Focus Iron REPL"})
      vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>', {desc = "Hide Iron REPL"})
		end,
		config = function()
			require("iron.core").setup({
				config = {
          repl_open_cmd = require('iron.view').center '40%',
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
    event = { 'BufReadPost', 'BufNewFile' },
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
        NeogitCommitMessage = { 'gitlint' },
				c = { "flawfinder" },
				cpp = { "flawfinder" },
				lua = { "selene" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
				vim = { "vint" },
			}

      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        pattern = { '.github/**/*.yaml', '.github/**/*.yml' },
        callback = function()
          require('lint').try_lint 'actionlint'
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
	{
		"nanozuki/tabby.nvim",
		event = "User ActuallyEditing",
		config = function()
			local theme = {
				fill = { fg = "#222222", bg = "#222222" },
				current_tab = { fg = "#e9e9e9", bg = "#222222" },
				tab = { fg = "#666666", bg = "#222222" },
			}
			local tabby_api = require("tabby.module.api")
			require("tabby.tabline").set(function(line)
				local num_tabs = #tabby_api.get_tabs()
				local tabs = line.tabs().foreach(function(tab)
					local hl = tab.is_current() and theme.current_tab or theme.tab
					local tab_separator = (tab.number() < num_tabs)
							and line.sep(
								"／ ",
								{ fg = "#222222", bg = "#e9e9e9", style = "bold" },
								{ fg = "#e9e9e9", bg = "#222222", style = "bold" }
							)
						or line.sep(
							"",
							{ fg = "#222222", bg = "#e9e9e9", style = "bold" },
							{ fg = "#e9e9e9", bg = "#222222", style = "bold" }
						)
					local num_wins = #tabby_api.get_tab_wins(tab.id)
					local win_idx = 1
					return {
						tab.wins().foreach(function(win)
							local window_separator = (win_idx < num_wins) and "  " or ""
							win_idx = win_idx + 1
							return {
								win.file_icon(),
								win.buf_name(),
								win.buf().is_changed() and "●" or "",
								window_separator,
								margin = " ",
								hl = hl,
							}
						end),
						tab_separator,
						hl = hl,
					}
				end)
				return {
					line.spacer(),
					tabs,
					line.spacer(),
					buf_name = { mode = "unique" },
					hl = theme.fill,
				}
			end)
		end,
	},
	{
		"stevearc/overseer.nvim",
		config = true,
		cmd = { "OverseerRun", "OverseerToggle" },
	},
	{
		"chrisgrieser/nvim-various-textobjs",
		opts = { useDefaultKeymaps = true },
    event = { 'BufReadPost', 'BufNewFile' },
	},
	{
		"nanozuki/tabby.nvim",
		event = "User ActuallyEditing",
		config = function()
			local theme = {
				fill = { fg = "#222222", bg = "#222222" },
				current_tab = { fg = "#e9e9e9", bg = "#222222" },
				tab = { fg = "#666666", bg = "#222222" },
			}
			local tabby_api = require("tabby.module.api")
			require("tabby.tabline").set(function(line)
				local num_tabs = #tabby_api.get_tabs()
				local tabs = line.tabs().foreach(function(tab)
					local hl = tab.is_current() and theme.current_tab or theme.tab
					local tab_separator = (tab.number() < num_tabs)
							and line.sep(
								"／ ",
								{ fg = "#222222", bg = "#e9e9e9", style = "bold" },
								{ fg = "#e9e9e9", bg = "#222222", style = "bold" }
							)
						or line.sep(
							"",
							{ fg = "#222222", bg = "#e9e9e9", style = "bold" },
							{ fg = "#e9e9e9", bg = "#222222", style = "bold" }
						)
					local num_wins = #tabby_api.get_tab_wins(tab.id)
					local win_idx = 1
					return {
						tab.wins().foreach(function(win)
							local window_separator = (win_idx < num_wins) and "  " or ""
							win_idx = win_idx + 1
							return {
								win.file_icon(),
								win.buf_name(),
								win.buf().is_changed() and "●" or "",
								window_separator,
								margin = " ",
								hl = hl,
							}
						end),
						tab_separator,
						hl = hl,
					}
				end)
				return {
					line.spacer(),
					tabs,
					line.spacer(),
					buf_name = { mode = "unique" },
					hl = theme.fill,
				}
			end)
		end,
	},
	{
		"linux-cultist/venv-selector.nvim",
		cmd = "VenvSelect",
		opts = {},
		keys = { { "<leader>pv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" } },
	},
	{
		"chrisgrieser/nvim-rulebook",
		keys = {
			{
				"<leader>i",
				function()
					require("rulebook").ignoreRule()
				end,
			},
			{
				"<leader>l",
				function()
					require("rulebook").lookupRule()
				end,
			},
		},
	},
}
