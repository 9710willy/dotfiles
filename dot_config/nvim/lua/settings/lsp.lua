local border = {
	{ "🭽", "FloatBorder" },
	{ "▔", "FloatBorder" },
	{ "🭾", "FloatBorder" },
	{ "▕", "FloatBorder" },
	{ "🭿", "FloatBorder" },
	{ "▁", "FloatBorder" },
	{ "🭼", "FloatBorder" },
	{ "▏", "FloatBorder" },
}

vim.diagnostic.config({
	virtual_lines = { current_line = true },
	virtual_text = false,
	float = { border = border },
	update_in_insert = false,
	underline = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "RedSign",
			[vim.diagnostic.severity.WARN] = "YellowSign",
			[vim.diagnostic.severity.INFO] = "WhiteSign",
			[vim.diagnostic.severity.HINT] = "BlueSign",
		},
	},
})

local function setup_keymaps(client, bufnr)
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gd", "<cmd>Glance definitions<CR>", opts)
	vim.keymap.set("n", "gi", "<cmd>Glance implementations<CR>", opts)
	vim.keymap.set("n", "gS", vim.lsp.buf.signature_help, opts)
	vim.keymap.set("n", "gTD", vim.lsp.buf.type_definition, opts)
	vim.keymap.set({ "n", "v" }, "<leader>rn", function()
		return ":IncRename " .. vim.fn.expand("<cword>")
	end, { buffer = bufnr, expr = true })
	vim.keymap.set("n", "gr", "<cmd>Glance references<CR>", opts)
	vim.keymap.set({ "n", "v" }, "gA", vim.lsp.buf.code_action, opts)

	if client:supports_method("textDocument/documentHighlight") then
		local highlight_group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
		vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = bufnr })
		vim.api.nvim_create_autocmd("CursorHold", {
			group = highlight_group,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = highlight_group,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end
end

local client_capabilities = require("cmp_nvim_lsp").default_capabilities()
client_capabilities.offsetEncoding = { "utf-16" }

-- Buffer-local LSP behavior for every server. An LspAttach autocmd
-- cannot be replaced by a per-server on_attach in after/lsp/*.lua
-- (a global on_attach in vim.lsp.config('*') was); per-server
-- on_attach now only adds server-specific extras.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_setup", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		local bufnr = args.buf

		if client:supports_method("textDocument/documentSymbol") then
			require("nvim-navic").attach(client, bufnr)
		end

		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		setup_keymaps(client, bufnr)
	end,
})

-- Global LSP configuration (applies to all servers)
vim.lsp.config("*", {
	capabilities = client_capabilities,
})

-- clangd_extensions no longer starts the server. The server itself is
-- configured in after/lsp/clangd.lua and enabled below like every other
-- server. This call only sets the extension options (AST viewer icons).
require("clangd_extensions").setup({
	ast = {
		role_icons = {
			type = "",
			declaration = "",
			expression = "",
			specifier = "",
			statement = "",
			["template argument"] = "",
		},
		kind_icons = {
			Compound = "",
			Recovery = "",
			TranslationUnit = "",
			PackExpansion = "",
			TemplateTypeParm = "",
			TemplateTemplateParm = "",
			TemplateParamObject = "",
		},
	},
})

-- Enable all LSP servers (configs loaded from lsp/*.lua)
vim.lsp.enable({
	"bashls",
	"clangd",
	"neocmake",
	"cssls",
	"dockerls",
	"eslint",
	"html",
	"jsonls",
	"julials",
	"marksman",
	"ocamllsp",
	"pyright",
	"ruff",
	"rust_analyzer",
	"lua_ls",
	"tailwindcss",
	"texlab",
	"ltex_plus",
	"vtsls",
	"vimls",
	"yamlls",
})
