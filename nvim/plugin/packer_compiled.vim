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
  ["completion-nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/completion-nvim"
  },
  fzf = {
    config = { "\27LJ\2\n,\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\17settings.fzf\frequire\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/fzf"
  },
  ["fzf-checkout.vim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/fzf-checkout.vim"
  },
  ["fzf.vim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/fzf.vim"
  },
  gruvbox = {
    config = { "\27LJ\2\n/\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\20settings.colors\frequire\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/gruvbox"
  },
  ["gv.vim"] = {
    config = { "\27LJ\2\n,\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\17settings.git\frequire\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/gv.vim"
  },
  ["lsp_extensions.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/lsp_extensions.nvim"
  },
  ["nlua.nvim"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nlua.nvim"
  },
  ["nvim-lspconfig"] = {
    config = { "\27LJ\2\n~\0\0\3\0\6\0\b6\0\0\0'\2\1\0B\0\2\0016\0\2\0009\0\3\0005\1\5\0=\1\4\0K\0\1\0\1\4\0\0\nexact\14substring\nfuzzy&completion_matching_strategy_list\6g\bvim\17settings.lsp\frequire\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nvim-lspconfig"
  },
  ["nvim-lsputils"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/nvim-lsputils"
  },
  ["nvim-treesitter"] = {
    config = { "\27LJ\2\n3\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\24settings.treesitter\frequire\0" },
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
  popfix = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/popfix"
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
    config = { "\27LJ\2\n2\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\23settings.telescope\frequire\0" },
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/telescope.nvim"
  },
  undotree = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/undotree"
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
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-dispatch"
  },
  ["vim-fugitive"] = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vim-fugitive"
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
  vimspector = {
    loaded = true,
    path = "/Users/will/.local/share/nvim/site/pack/packer/start/vimspector"
  }
}

-- Config for: gv.vim
try_loadstring("\27LJ\2\n,\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\17settings.git\frequire\0", "config", "gv.vim")
-- Config for: vim-bujo
try_loadstring("\27LJ\2\nG\0\0\2\0\4\0\0056\0\0\0009\0\1\0'\1\3\0=\1\2\0K\0\1\0\22$HOME/.cache/bujo\24bujo#todo_file_path\6g\bvim\0", "config", "vim-bujo")
-- Config for: nvim-lspconfig
try_loadstring("\27LJ\2\n~\0\0\3\0\6\0\b6\0\0\0'\2\1\0B\0\2\0016\0\2\0009\0\3\0005\1\5\0=\1\4\0K\0\1\0\1\4\0\0\nexact\14substring\nfuzzy&completion_matching_strategy_list\6g\bvim\17settings.lsp\frequire\0", "config", "nvim-lspconfig")
-- Config for: fzf
try_loadstring("\27LJ\2\n,\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\17settings.fzf\frequire\0", "config", "fzf")
-- Config for: nvim-treesitter
try_loadstring("\27LJ\2\n3\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\24settings.treesitter\frequire\0", "config", "nvim-treesitter")
-- Config for: gruvbox
try_loadstring("\27LJ\2\n/\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\20settings.colors\frequire\0", "config", "gruvbox")
-- Config for: telescope.nvim
try_loadstring("\27LJ\2\n2\0\0\3\0\2\0\0046\0\0\0'\2\1\0B\0\2\1K\0\1\0\23settings.telescope\frequire\0", "config", "telescope.nvim")
END

catch
  echohl ErrorMsg
  echom "Error in packer_compiled: " .. v:exception
  echom "Please check your config for correctness"
  echohl None
endtry
