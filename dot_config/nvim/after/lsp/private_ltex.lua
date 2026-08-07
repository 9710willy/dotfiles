return {
	cmd = { "ltex-ls" },
	filetypes = { "bib", "gitcommit", "org", "plaintex", "rst", "rnoweb", "tex", "pandoc", "quarto", "rmd", "context" },
	-- Global buffer setup runs via the LspAttach autocmd in
	-- lua/settings/lsp.lua; this only adds the ltex_extra integration.
	on_attach = function()
		require("ltex_extra").setup({})
	end,
	settings = {
		ltex = {
			checkFrequency = "save",
			additionalRules = { enablePickyRules = true },
		},
	},
}
