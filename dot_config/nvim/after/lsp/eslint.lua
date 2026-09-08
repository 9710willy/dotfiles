return {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
	-- ESLint uses push diagnostics. Neovim's pull request fails for this server.
	on_attach = function(client)
		client.server_capabilities.diagnosticProvider = nil
	end,
	settings = {
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = { enable = true },
		},
		codeActionOnSave = { mode = "problems" },
		format = false,
		nodePath = "",
		onIgnoredFiles = "off",
		problems = { shortenToSingleLine = false },
		quiet = false,
		rulesCustomizations = {},
		run = "onType",
		validate = "on",
		workingDirectory = { mode = "auto" },
	},
}
