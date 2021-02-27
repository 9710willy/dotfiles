local actions = require('telescope.actions')

local mappings = {
    -- horizontal split
    ["<C-x>"] = false,
    ["<C-s>"] = actions.select_horizontal,
    -- next | prev
    ["j"] = false,
    ["k"] = false,
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
    -- use esc for exit no normal mode
    ["<esc>"] = actions.close
}

require("telescope").setup {
    defaults = {
        mappings = {
            i = mappings,
            n = mappings
        },
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case"
        },
        prompt_position = "top",
        prompt_prefix = ">",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_defaults = {},
        file_sorter = require "telescope.sorters".get_fuzzy_file,
        file_ignore_patterns = {".*node_modules.*"},
        generic_sorter = require "telescope.sorters".get_generic_fuzzy_sorter,
        shorten_path = true,
        winblend = 10,
        width = 0.75,
        preview_cutoff = 50,
        results_height = 1,
        results_width = 0.8,
        border = {},
        borderchars = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
        color_devicons = true,
        use_less = true,
        set_env = {["COLORTERM"] = "truecolor"}, -- default { }, currently unsupported for shells like cmd.exe / powershell.exe
        file_previewer = require "telescope.previewers".cat.new, -- For buffer previewer use `require'telescope.previewers'.vim_buffer_cat.new`
        grep_previewer = require "telescope.previewers".vimgrep.new, -- For buffer previewer use `require'telescope.previewers'.vim_buffer_vimgrep.new`
        qflist_previewer = require "telescope.previewers".qflist.new -- For buffer previewer use `require'telescope.previewers'.vim_buffer_qflist.new`
    }
}
