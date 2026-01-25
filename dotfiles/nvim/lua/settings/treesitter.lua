require('nvim-treesitter.configs').setup {
  auto_install = true,
  highlight = {
    enable = true,
    max_file_lines = 5000,
    disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,
  },
  indent = { enable = false },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<C-space>',
      node_incremental = '<C-space>',
      scope_incremental = false,
      node_decremental = '<bs>',
    },
  },
  refactor = {
    smart_rename = { enable = true, keymaps = { smart_rename = 'grr' } },
    highlight_definitions = { enable = false },
  },
  textsubjects = {
    enable = true,
    lookahead = true,
    max_file_lines = 5000,
    keymaps = {
      ['.'] = 'textsubjects-smart',
      [';'] = 'textsubjects-container-outer',
      ['i;'] = 'textsubjects-container-inner',
    },
  },
  endwise = { enable = true, disable = { 'noice' } },
  matchup = {
    enable = true,
    include_match_words = true,
    enable_quotes = true,
    disable = function(lang, buf)
      if lang == 'noice' then
        return true
      end

      return false
    end,
  },
}

-- Enable autotag (windwp/nvim-ts-autotag)
require('nvim-ts-autotag').setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = true,
  },
})

-- Treesitter-based folding (faster than syntax)
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
