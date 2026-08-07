-- Prefer the dedicated julia binary with a precompiled LanguageServer
-- environment when it exists. The old on_new_config hook is not part of
-- the vim.lsp.config protocol; resolve the command here instead. This
-- file is evaluated lazily, on the first julia buffer.
local julia_cmd = "julia"
local julia_env = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
if vim.uv.fs_stat(julia_env) then
	julia_cmd = julia_env
end

return {
	cmd = { julia_cmd, "--startup-file=no", "--history-file=no", "-e", "using LanguageServer; runserver()" },
	filetypes = { "julia" },
	settings = {
		julia = {
			format = { indent = 2 },
		},
	},
}
