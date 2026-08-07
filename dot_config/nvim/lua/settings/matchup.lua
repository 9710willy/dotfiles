local g = vim.g
g.matchup_matchparen_deferred = 1
g.matchup_matchparen_deferred_show_delay = 100
g.matchup_matchparen_hi_surround_always = 1
g.matchup_override_vimtex = 1
g.matchup_delim_start_plaintext = 0
g.matchup_transmute_enabled = 0
g.matchup_matchparen_offscreen = { method = "popup" }
-- Treesitter integration. The old nvim-treesitter module config
-- (matchup = { ... } in configs.setup) is gone; vim-matchup now reads
-- these variables directly.
g.matchup_treesitter_include_match_words = true
g.matchup_treesitter_enable_quotes = true
g.matchup_treesitter_disabled = { "noice" }
