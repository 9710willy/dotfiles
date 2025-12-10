local lsp = vim.lsp
local buf_keymap = vim.api.nvim_buf_set_keymap

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
  { float = { border = border } },
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

lsp.handlers['textDocument/publishDiagnostics'] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
  virtual_text = false,
  signs = true,
  update_in_insert = false,
  underline = true,
})

local keymap_opts = { noremap = true, silent = true }
local function setup_keymaps(client, _bufnr)
  buf_keymap(0, "n", "gD", "", vim.tbl_extend("keep", { callback = vim.lsp.buf.declaration }, keymap_opts))
  buf_keymap(0, "n", "gd", "<cmd>Glance definitions<CR>", keymap_opts)
  buf_keymap(0, "n", "gi", "<cmd>Glance implementations<CR>", keymap_opts)
  buf_keymap(0, "n", "gS", "", vim.tbl_extend("keep", { callback = vim.lsp.buf.signature_help }, keymap_opts))
  buf_keymap(0, "n", "gTD", "", vim.tbl_extend("keep", { callback = vim.lsp.buf.type_definition }, keymap_opts))
  buf_keymap(0, "n", "<leader>rn", "", {
    callback = function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end,
    expr = true,
  })
  buf_keymap(0, "v", "<leader>rn", "", {
    callback = function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end,
    expr = true,
  })
  buf_keymap(0, "n", "gr", "<cmd>Glance references<CR>", keymap_opts)
  buf_keymap(0, "n", "gA", "", vim.tbl_extend("keep", { callback = vim.lsp.buf.code_action }, keymap_opts))
  buf_keymap(0, "v", "gA", "", vim.tbl_extend("keep", { callback = vim.lsp.buf.code_action }, keymap_opts))

  if client.server_capabilities.documentHighlightProvider then
    local lsp_aucmds = vim.api.nvim_create_augroup("lsp_aucmds", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = lsp_aucmds,
      buffer = 0,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = lsp_aucmds,
      buffer = 0,
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

  vim.lsp.inlay_hint.enable(
    client.server_capabilities.inlayHintProvider ~= nil
    and client.server_capabilities.inlayHintProvider ~= false
  )

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
      "--cross-file-rename",
      "--all-scopes-completion",
      "--log=error",
      "--suggest-missing-includes",
      "--pch-storage=memory",
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
  'ocamllsp',
  'pyright',
  'ruff',
  'rust_analyzer',
  'lua_ls',
  'texlab',
  'ltex',
  'ts_ls',
  'vimls',
})
