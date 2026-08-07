return {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
	-- ESLint uses push diagnostics, not pull — disable neovim 0.11+ pull diagnostics
	-- to prevent "request textDocument/diagnostic failed" errors.
	-- Global buffer setup (keymaps, navic, inlay hints) runs via the
	-- LspAttach autocmd in lua/settings/lsp.lua.
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
		format = false, -- Let other formatters handle this
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
