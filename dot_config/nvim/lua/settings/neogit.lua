require("neogit").setup({
	disable_signs = true,
	integrations = { diffview = true },
	sections = {
		untracked = {
			folded = false,
		},
		unstaged = {
			folded = false,
		},
		staged = {
			folded = false,
		},
		stashes = {
			folded = true,
		},
		unpulled = {
			folded = false,
			hidden = false,
		},
		unmerged = {
			folded = false,
			hidden = false,
		},
		recent = {
			folded = false,
		},
	},
})
