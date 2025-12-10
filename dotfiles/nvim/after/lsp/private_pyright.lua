return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  settings = {
    python = {
      analysis = { useLibraryCodeForTypes = true },
      formatting = { provider = "yapf" },
      linting = { pytypeEnabled = true },
    },
  },
}
