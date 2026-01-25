-- Auto-detect flat config vs legacy based on project files
local function uses_flat_config(root_dir)
  local flat_configs = { "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs" }
  for _, config in ipairs(flat_configs) do
    if vim.uv.fs_stat(root_dir .. "/" .. config) then
      return true
    end
  end
  return false
end

return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  on_new_config = function(config, root_dir)
    config.settings.useFlatConfig = uses_flat_config(root_dir)
  end,
  settings = {
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = { enable = true },
    },
    codeActionOnSave = { mode = "problems" },
    format = false,
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
