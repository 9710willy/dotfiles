return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  settings = {
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = { enable = true },
    },
    codeActionOnSave = { mode = "problems" },
    format = false, -- Let other formatters handle this
    nodePath = "",
    onIgnoredFiles = "off",
    problems = { shortenToSingleLine = false },
    quiet = false,
    rulesCustomizations = {},
    run = "onType",
    validate = "on",
    workingDirectory = { mode = "auto" },
  },
}
