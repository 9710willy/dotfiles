return {
	cmd = { "ltex-ls-plus" },
	filetypes = { "bib", "gitcommit", "org", "plaintex", "rst", "rnoweb", "tex", "pandoc", "quarto", "rmd", "context" },
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
