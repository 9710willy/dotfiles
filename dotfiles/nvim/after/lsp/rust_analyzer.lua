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
      checkOnSave = {
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
