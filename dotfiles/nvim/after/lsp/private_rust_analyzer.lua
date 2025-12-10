return {
  filetypes = { "rust" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      checkOnSave = {
        command = "clippy",
        extraArgs = { "--no-deps" },
      },
    },
  },
}
