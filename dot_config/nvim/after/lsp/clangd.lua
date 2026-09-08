return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--completion-style=bundled",
		"--header-insertion=iwyu",
		"--all-scopes-completion",
		"--log=error",
		"--pch-storage=memory",
		"--function-arg-placeholders=1", -- clangd 17+ requires a value
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	init_options = {
		clangdFileStatus = true,
		usePlaceholders = true,
		completeUnimported = true,
		semanticHighlighting = true,
	},
}
