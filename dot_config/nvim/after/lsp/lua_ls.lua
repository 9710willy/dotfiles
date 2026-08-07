return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	-- lazydev.nvim handles neovim lua setup automatically (replaced neodev)
	single_file_support = true,
	settings = {
		Lua = {
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
			completion = {
				workspaceWord = true,
				callSnippet = "Both",
			},
			runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
			diagnostics = {
				globals = { "vim" },
				groupSeverity = {
					strong = "Warning",
					strict = "Warning",
				},
				groupFileStatus = {
					["ambiguity"] = "Opened",
					["await"] = "Opened",
					-- codestyle off: stylua formats, selene lints
					["codestyle"] = "None",
					["duplicate"] = "Opened",
					["global"] = "Opened",
					["luadoc"] = "Opened",
					["redefined"] = "Opened",
					["strict"] = "Opened",
					["strong"] = "Opened",
					["type-check"] = "Opened",
					["unbalanced"] = "Opened",
					["unused"] = "Opened",
				},
				unusedLocalExclude = { "_*" },
			},
			-- formatting stays with stylua (conform.nvim)
			format = { enable = false },
			telemetry = { enable = false },
		},
	},
}
