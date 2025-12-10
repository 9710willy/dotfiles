-- Add 'sass' filetype (not in nvim-lspconfig default)
return {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less", "sass" },
}
