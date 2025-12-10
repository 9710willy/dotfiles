return {
  cmd = { "julia", "--startup-file=no", "--history-file=no", "-e", 'using LanguageServer; runserver()' },
  filetypes = { "julia" },
  on_new_config = function(new_config, _)
    local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
    if vim.uv.fs_stat(julia) then
      new_config.cmd[1] = julia
    end
  end,
  settings = {
    julia = {
      format = { indent = 2 },
    },
  },
}
