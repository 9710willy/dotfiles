local lsp = vim.lsp

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

vim.diagnostic.config {
  virtual_lines = { only_current_line = true },
  virtual_text = false,
  float = { border = border },
  update_in_insert = false,
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'RedSign',
      [vim.diagnostic.severity.WARN] = 'YellowSign',
      [vim.diagnostic.severity.INFO] = 'WhiteSign',
      [vim.diagnostic.severity.HINT] = 'BlueSign',
    },
  },
}

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

  if client.server_capabilities.documentHighlightProvider then
    local lsp_aucmds = vim.api.nvim_create_augroup("lsp_aucmds", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = lsp_aucmds,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = lsp_aucmds,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

local client_capabilities = require("cmp_nvim_lsp").default_capabilities()
client_capabilities.offsetEncoding = { "utf-16" }

local function on_attach(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end

  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  setup_keymaps(client, bufnr)
end

-- Global LSP configuration (applies to all servers)
vim.lsp.config('*', {
  capabilities = client_capabilities,
  on_attach = on_attach,
})

-- clangd configured through clangd_extensions (needs special handling)
require("clangd_extensions").setup({
  server = {
    on_attach = on_attach,
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--completion-style=bundled",
      "--header-insertion=iwyu",
      "--all-scopes-completion",
      "--log=error",
      "--pch-storage=memory",
      "--function-arg-placeholders",
    },
    init_options = {
      clangdFileStatus = true,
      usePlaceholders = true,
      completeUnimported = true,
      semanticHighlighting = true,
    },
    capabilities = client_capabilities,
  },
  extensions = {
    autoSetHints = false,
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
  },
})

-- Enable all LSP servers (configs loaded from lsp/*.lua)
vim.lsp.enable({
  'bashls',
  'neocmake',
  'cssls',
  'dockerls',
  'html',
  'jsonls',
  'julials',
  'marksman',
  'ocamllsp',
  'pyright',
  'ruff',
  'rust_analyzer',
  'lua_ls',
  'texlab',
  'ltex',
  'vtsls',
  'vimls',
  'yamlls',
})
