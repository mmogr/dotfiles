-- Autocommands that need no plugin

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight yanked text. See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('user-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
