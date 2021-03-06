vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
    use {'wbthomason/packer.nvim', opt = true}

    --use { 'gruvbox-community/gruvbox',
    --config = function()
    --    require'settings.colors'
    --end,
    --}

    use {"npxbr/gruvbox.nvim",
    requires = {"rktjmp/lush.nvim"},
    config = function()
        require'settings.colors'
    end,
    }

    --Neovim LSP
    use {
     'neovim/nvim-lspconfig',
     requires = {
         {'tjdevries/nlua.nvim'},
         {'tjdevries/lsp_extensions.nvim'},
         {'nvim-lua/completion-nvim'},
     },
     config = function()
         require'settings.lsp'
         vim.g.completion_matching_strategy_list = {'exact', 'substring', 'fuzzy'}
     end,
    }

    --Tresitter
    use { 'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function ()
        require'settings.treesitter'
    end,
    }

    --Debugger
    use { 'puremourning/vimspector', requires = { 'szw/vim-maximizer' } }

    use { 'junegunn/gv.vim',
    requires = {'tpope/vim-fugitive'},
    config = function()
        require'settings.git'
    end }
    use { 'vim-utils/vim-man' }
    use { 'mbbill/undotree' }
    use { 'junegunn/fzf',
    run = function() vim.fn['fzf#install']() end,
    config = function()
        require'settings.fzf'
    end,
    }
    use { 'junegunn/fzf.vim'}
    use { 'stsewd/fzf-checkout.vim'}

    use { 'vuciv/vim-bujo',
    config = function()
        vim.g['bujo#todo_file_path'] = '$HOME/.cache/bujo'
    end }
    use { 'tpope/vim-dispatch' }

    use { 'octol/vim-cpp-enhanced-highlight' }
    use { 'tpope/vim-projectionist' }

    --Telescope
    use {
     'nvim-telescope/telescope.nvim',
     requires = {
         {'nvim-lua/popup.nvim'},
         {'nvim-lua/plenary.nvim'},
         {'~/plugins/telescope-fzy-native.nvim'}
     },
     config = function ()
         require'settings.telescope'
     end,
    }
    --Cheat Sheet
    use { 'dbeniamine/cheat.sh-vim' }

end)

