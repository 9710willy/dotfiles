local lsp = require'lspconfig'
local completion = require'completion'

local eslint = {
    lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
    lintIgnoreExitCode = true,
    lintStdin = true,
}

local luafmt = {
    formatCommand = "luafmt -i 4 -l 100 --stdin",
    formatStdin = true,
}

local prettier = {
    formatCommand = ([[
        ./node_modules/.bin/prettier
        ${--config-precedence:configPrecedence}
        ${--tab-width:tabWidth}
        ${--single-quote:singleQuote}
        ${--trailing-comma:trailingComma}
    ]]):gsub(
        "\n",
        ""
    )
}

vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
        underline = true,
        signs = true,
        update_in_insert = true,
        virtual_text = true,
    }
)

-- Prettier
local format_options_prettier = {
    tabWidth = 4,
    useTabs = false,
    singleQuote = true,
    trailingComma = "all",
    configPrecedence = "prefer-file"
}

vim.g.format_options_typescript = format_options_prettier
vim.g.format_options_javascript = format_options_prettier
vim.g.format_options_typescriptreact = format_options_prettier
vim.g.format_options_javascriptreact = format_options_prettier
vim.g.format_options_json = format_options_prettier
vim.g.format_options_css = format_options_prettier
vim.g.format_options_scss = format_options_prettier
vim.g.format_options_html = format_options_prettier
vim.g.format_options_yaml = format_options_prettier
vim.g.format_options_markdown = format_options_prettier

-- Utility servers
local map = function(type, key, value)
    vim.fn.nvim_buf_set_keymap(0,type,key,value,{noremap = true, silent = true});
end

FormatToggle = function(value)
    vim.g[string.format("format_disabled_%s", vim.bo.filetype)] = value
end

vim.cmd [[command! FormatDisable lua FormatToggle(true)]]
vim.cmd [[command! FormatEnable lua FormatToggle(false)]]

_G.formatting = function()
    if not vim.g[string.format("format_disabled_%s", vim.bo.filetype)] then
        vim.lsp.buf.formatting(vim.g[string.format("format_options_%s", vim.bo.filetype)] or {})
    end
end

local on_attach = function(client)
    print("'" .. client.name .. "' language server started" )
    completion.on_attach(client)

    if client.resolved_capabilities.document_formatting then
        vim.cmd [[augroup Format]]
        vim.cmd [[autocmd! * <buffer>]]
        vim.cmd [[autocmd BufWritePost <buffer> lua formatting()]]
        vim.cmd [[augroup END]]
    end

    -- GOTO mappings
    map('n','gD','<cmd>lua vim.lsp.buf.declaration()<CR>')
    map('n','gd','<cmd>lua vim.lsp.buf.definition()<CR>')
    map('n','K','<cmd>lua vim.lsp.buf.hover()<CR>')
    map('n','gr','<cmd>lua vim.lsp.buf.references()<CR>')
    map('n','gs','<cmd>lua vim.lsp.buf.signature_help()<CR>')
    map('n','gi','<cmd>lua vim.lsp.buf.implementation()<CR>')
    map('n','<leader>gt','<cmd>lua vim.lsp.buf.type_definition()<CR>')
    map('n','<leader>gw','<cmd>lua vim.lsp.buf.document_symbol()<CR>')
    map('n','<leader>gW','<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
    -- ACTION mappings
    map('n','<leader>ah',  '<cmd>lua vim.lsp.buf.hover()<CR>')
    map('n','<leader>af', '<cmd>lua vim.lsp.buf.code_action()<CR>')
    map('n','<leader>ar',  '<cmd>lua vim.lsp.buf.rename()<CR>')
    -- Few language severs support these three
    map('n','<leader>=',  '<cmd>lua vim.lsp.buf.formatting()<CR>')
    map('n','<leader>ai',  '<cmd>lua vim.lsp.buf.incoming_calls()<CR>')
    map('n','<leader>ao',  '<cmd>lua vim.lsp.buf.outgoing_calls()<CR>')
    -- Diagnostics mapping
    map('n','<leader>ee', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')
    map('n','<leader>en', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
    map('n','<leader>ep', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
end

lsp.tsserver.setup {
    -- Avoid TSServer clashing with Prettier
    on_attach = function(client)

    if client.config.flags then
      client.config.flags.allow_incremental_sync = true
    end

        client.resolved_capabilities.document_formatting = false
        on_attach(client)
    end
}
lsp.gopls.setup{ on_attach = on_attach }

-- https://github.com/iamcco/vim-language-server
lsp.vimls.setup { on_attach = on_attach }

-- https://github.com/rcjsuen/dockerfile-language-server-nodejs
lsp.dockerls.setup {
    on_attach = on_attach,
    filetypes = { "Dockerfile", "dockerfile", "Dockerfile.dev" }
}

-- https://github.com/vscode-langservers/vscode-json-languageserver
lsp.jsonls.setup {
    on_attach = on_attach,
    cmd = {"vscode-json-languageserver", "--stdio"}
}

-- https://github.com/redhat-developer/yaml-language-server
lsp.yamlls.setup {on_attach = on_attach}

local function eslint_config_exists()
  local eslintrc = vim.fn.glob(".eslintrc*", 0, 1)

  if not vim.tbl_isempty(eslintrc) then
    return true
  end

  if vim.fn.filereadable("package.json") then
    if vim.fn.json_decode(vim.fn.readfile("package.json"))["eslintConfig"] then
      return true
    end
  end

  return false
end

lsp.efm.setup {
    on_attach = function(client)
        client.resolved_capabilities.document_formatting = true
        on_attach(client)
    end,
    init_options = {documentFormatting = true},
    root_dir = function()
        if not eslint_config_exists() then
            return nil
        end
        return vim.fn.getcwd()
    end,
    settings = {
        rootMarkers = {".git/"},
        languages = {
            lua = {luafmt},
            --go = {golint, goimports},
            typescript = {prettier, eslint},
            javascript = {prettier, eslint},
            typescriptreact = {prettier, eslint},
            javascriptreact = {prettier, eslint},
            ["javascript.jsx"] = {prettier, eslint},
            ["typescript.tsx"] = {prettier, eslint},
            yaml = {prettier},
            json = {prettier},
            html = {prettier},
            scss = {prettier},
            css = {prettier},
            markdown = {prettier},
            graphql= {prettier},
            --tf = {terraform}
        }
    },
    filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescript.tsx",
        "typescriptreact"
    }
}

-- Lua language server
local system_name
if vim.fn.has("mac") == 1 then
  system_name = "macOS"
elseif vim.fn.has("unix") == 1 then
  system_name = "Linux"
elseif vim.fn.has('win32') == 1 then
  system_name = "Windows"
else
  print("Unsupported system for sumneko")
end

local sumneko_root_path = '/Users/will/langservers/lua-language-server'
local sumneko_binary = sumneko_root_path.."/bin/"..system_name.."/lua-language-server"
lsp.sumneko_lua.setup({
    on_attach = on_attach,
    cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"};
    settings = {
        Lua = {
            diagnostics = {
                enable = true,
                globals = { "vim", "use" },
            },
        }
    },
})

vim.lsp.handlers["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end

  if not vim.api.nvim_buf_get_option(bufnr, "modified") then
    local view = vim.fn.winsaveview()
    vim.lsp.util.apply_text_edits(result, bufnr)
    vim.fn.winrestview(view)
    if bufnr == vim.api.nvim_get_current_buf() then
      vim.api.nvim_command("noautocmd :update")
    end
  end
end
