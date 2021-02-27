vim.g.fzf_layout = { window = { width = 0.8, height = 0.8 } }
local vfalse = vim.api.nvim_get_vvar('false')
vim.g.fzf_branch_actions = {
rebase = {
    prompt = 'Rebase> ',
    execute = 'echo system("{git} rebase {branch}")',
    multiple = vfalse,
    keymap = 'ctrl-r',
    required = 'branch',
    confirm = vfalse,
},
track = {
    prompt = 'Track >',
    execute = 'echo system("{git} checkout --track {branch}")',
    multiple = vfalse,
    keymap = 'ctrl-t',
    required = 'branch',
    confirm = vfalse,
    },
}
