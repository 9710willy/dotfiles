return {
  cmd = { "/opt/homebrew/bin/ltex-ls" },
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
