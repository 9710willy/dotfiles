return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
				loadOutDirsFromCheck = true,
			},
			procMacro = {
				enable = true,
			},
			-- checkOnSave is a boolean now; the check settings moved to "check"
			checkOnSave = true,
			check = {
				command = "clippy",
				extraArgs = { "--no-deps" },
			},
			completion = {
				autoimport = { enable = true },
				postfix = { enable = true },
			},
			imports = {
				granularity = { group = "module" },
				prefix = "self",
			},
			inlayHints = {
				bindingModeHints = { enable = true },
				closureCaptureHints = { enable = true },
				closureReturnTypeHints = { enable = "with_block" },
				lifetimeElisionHints = { enable = "skip_trivial" },
			},
		},
	},
}
