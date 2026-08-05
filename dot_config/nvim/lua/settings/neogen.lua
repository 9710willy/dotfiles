local neogen = require 'neogen'

neogen.setup { enabled = true, jump_map = '<tab>' }
vim.keymap.set('n', '<localleader>d', function()
  require('neogen').generate()
end)
vim.keymap.set('n', '<localleader>df', function()
  require('neogen').generate { type = 'func' }
end)
vim.keymap.set('n', '<localleader>dc', function()
  require('neogen').generate { type = 'class' }
end)
