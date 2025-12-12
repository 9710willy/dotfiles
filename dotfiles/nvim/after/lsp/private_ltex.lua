return {
  cmd = { "ltex-ls" },
  filetypes = { "bib", "gitcommit", "org", "plaintex", "rst", "rnoweb", "tex", "pandoc", "quarto", "rmd", "context" },
  on_attach = function(client, bufnr)
    require("ltex_extra").setup({})
  end,
  settings = {
    ltex = {
      checkFrequency = "save",
      additionalRules = { enablePickyRules = true },
    },
  },
}
