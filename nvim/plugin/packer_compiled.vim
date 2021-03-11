" Automatically generated packer.nvim plugin loader code

if !has('nvim-0.5')
  echohl WarningMsg
  echom "Invalid Neovim version for packer.nvim!"
  echohl None
  finish
endif

packadd packer.nvim

try

lua << END
local package_path_str = "/Users/will/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/will/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/will/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/will/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/will/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    print('Error running ' .. component .. ' for ' .. name)
    error(result)
  end
  return result
end

_G.packer_plugins = {
  ["cheat.sh-vim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/cheat.sh-vim"
  },
  fzf = {
    config = { "require('settings.fzf')" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/fzf"
  },
  ["fzf-checkout.vim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/fzf-checkout.vim"
  },
  ["gruvbox.nvim"] = {
    config = { "require('settings.colors')" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/gruvbox.nvim"
  },
  ["gv.vim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/gv.vim"
  },
  ["lsp_extensions.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/lsp_extensions.nvim"
  },
  ["lush.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/lush.nvim"
  },
  ["nlua.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nlua.nvim"
  },
  ["nvim-compe"] = {
    after_files = { "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_buffer.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_calc.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_nvim_lsp.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_nvim_lua.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_omni.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_path.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_snippets_nvim.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_spell.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_tags.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_treesitter.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_ultisnips.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_vim_lsc.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_vim_lsp.vim", "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe/after/plugin/compe_vsnip.vim" },
    config = { "require('settings.compe')" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/nvim-compe"
  },
  ["nvim-lspconfig"] = {
    config = { "require('settings.lsp')" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nvim-lspconfig"
  },
  ["nvim-treesitter"] = {
    config = { "require('settings.treesitter')" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nvim-treesitter"
  },
  ["packer.nvim"] = {
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/popup.nvim"
  },
  ["telescope-fzy-native.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/telescope-fzy-native.nvim"
  },
  ["telescope.nvim"] = {
    config = { "require('settings.telescope')" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/telescope.nvim"
  },
  undotree = {
    commands = { "UndotreeShow" },
    config = { "vim.g.undotree_SetFocusWhenToggle = 1" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/undotree"
  },
  ["vim-bujo"] = {
    config = { "\27LJ\2\nG\0\0\2\0\4\0\0056\0\0\0009\0\1\0'\1\3\0=\1\2\0K\0\1\0\22$HOME/.cache/bujo\24bujo#todo_file_path\6g\bvim\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-bujo"
  },
  ["vim-cpp-enhanced-highlight"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-cpp-enhanced-highlight"
  },
  ["vim-dispatch"] = {
    commands = { "Dispatch", "Make", "Focus", "Start" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/vim-dispatch"
  },
  ["vim-fugitive"] = {
    commands = { "Git" },
    config = { "require('settings.git')" },
    loaded = false,
    needs_bufread = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/vim-fugitive"
  },
  ["vim-man"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-man"
  },
  ["vim-maximizer"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-maximizer"
  },
  ["vim-projectionist"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-projectionist"
  },
  ["vim-startuptime"] = {
    commands = { "StartupTime" },
    config = { "vim.g.startuptime_tries = 10" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/vim-startuptime"
  },
  ["vim-vsnip"] = {
    config = { "require('settings.vsnip')" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/will/.local/share/nvim/site/pack/packer/opt/vim-vsnip"
  },
  vimspector = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vimspector"
  }
}

-- Config for: gruvbox.nvim
require('settings.colors')
-- Config for: nvim-treesitter
require('settings.treesitter')
-- Config for: vim-bujo
try_loadstring("\27LJ\2\nG\0\0\2\0\4\0\0056\0\0\0009\0\1\0'\1\3\0=\1\2\0K\0\1\0\22$HOME/.cache/bujo\24bujo#todo_file_path\6g\bvim\0", "config", "vim-bujo")
-- Config for: nvim-lspconfig
require('settings.lsp')
-- Config for: telescope.nvim
require('settings.telescope')
-- Config for: fzf
require('settings.fzf')

-- Command lazy-loads
vim.cmd [[command! -nargs=* -range -bang -complete=file Focus lua require("packer.load")({'vim-dispatch'}, { cmd = "Focus", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Start lua require("packer.load")({'vim-dispatch'}, { cmd = "Start", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Git lua require("packer.load")({'vim-fugitive'}, { cmd = "Git", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file StartupTime lua require("packer.load")({'vim-startuptime'}, { cmd = "StartupTime", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file UndotreeShow lua require("packer.load")({'undotree'}, { cmd = "UndotreeShow", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Dispatch lua require("packer.load")({'vim-dispatch'}, { cmd = "Dispatch", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Make lua require("packer.load")({'vim-dispatch'}, { cmd = "Make", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]

vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Event lazy-loads
vim.cmd [[au InsertEnter * ++once lua require("packer.load")({'vim-vsnip', 'nvim-compe'}, { event = "InsertEnter *" }, _G.packer_plugins)]]
vim.cmd("augroup END")
END

catch
  echohl ErrorMsg
  echom "Error in packer_compiled: " .. v:exception
  echom "Please check your config for correctness"
  echohl None
endtry
