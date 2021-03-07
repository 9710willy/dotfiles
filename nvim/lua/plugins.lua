vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
    use {'wbthomason/packer.nvim', opt = true}

    use {
    'npxbr/gruvbox.nvim',
    requires = {'rktjmp/lush.nvim'},
    config = [[require('settings.colors')]]
    }

    --Neovim LSP
    use {
     'neovim/nvim-lspconfig',
     requires = {
         {'tjdevries/nlua.nvim'},
         {'tjdevries/lsp_extensions.nvim'},
     },
     config = [[require('settings.lsp')]]
    }

    use {'hrsh7th/nvim-compe', config = [[require('settings.compe')]], event = 'InsertEnter *'}
    use {'hrsh7th/vim-vsnip', config = [[require('settings.vsnip')]], event = 'InsertEnter *'}

    -- Tresitter
    use { 'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = [[require('settings.treesitter')]]
    }

    -- Debugger
    use { 'puremourning/vimspector', requires = { 'szw/vim-maximizer' } }

    --Git
    use {
    'tpope/vim-fugitive',
        cmd = 'Git',
        config = [[require('settings.git')]]
    }
    use { 'junegunn/gv.vim' }

    use { 'vim-utils/vim-man' }

    -- Undo tree
    use {
    'mbbill/undotree',
        cmd = 'UndotreeShow',
        config = [[vim.g.undotree_SetFocusWhenToggle = 1]]
    }

    use { 'junegunn/fzf', config = [[require('settings.fzf')]]}
    use { 'stsewd/fzf-checkout.vim'}

    use {
    'vuciv/vim-bujo',
    config = function()
        vim.g['bujo#todo_file_path'] = '$HOME/.cache/bujo'
    end
    }

    -- Async building & commands
    use { 'tpope/vim-dispatch', cmd = {'Dispatch', 'Make', 'Focus', 'Start'}}

    use { 'octol/vim-cpp-enhanced-highlight' }
    use { 'tpope/vim-projectionist' }

    -- Telescope
    use {
     'nvim-telescope/telescope.nvim',
     requires = {
         {'nvim-lua/popup.nvim'},
         {'nvim-lua/plenary.nvim'},
         {'~/plugins/telescope-fzy-native.nvim'}
     },
     config = [[require('settings.telescope')]]
    }

    -- Cheat Sheet
    use { 'dbeniamine/cheat.sh-vim' }

    -- Profiling
    use {'dstein64/vim-startuptime', cmd = 'StartupTime', config = [[vim.g.startuptime_tries = 10]]}

end)

