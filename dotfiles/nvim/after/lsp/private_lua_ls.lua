return {
  before_init = require("neodev.lsp").before_init,
  single_file_support = true,
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      completion = {
        workspaceWord = true,
        callSnippet = "Both",
      },
      runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
    diagnostics = {
      groupSeverity = {
        strong = "Warning",
        strict = "Warning",
      },
      groupFileStatus = {
        ["ambiguity"] = "Opened",
        ["await"] = "Opened",
        ["codestyle"] = "None",
        ["duplicate"] = "Opened",
        ["global"] = "Opened",
        ["luadoc"] = "Opened",
        ["redefined"] = "Opened",
        ["strict"] = "Opened",
        ["strong"] = "Opened",
        ["type-check"] = "Opened",
        ["unbalanced"] = "Opened",
        ["unused"] = "Opened",
      },
      unusedLocalExclude = { "_*" },
    },
    format = {
      enable = false,
      defaultConfig = {
        indent_style = "space",
        indent_size = "2",
        continuation_indent_size = "2",
      },
    },
  },
}
