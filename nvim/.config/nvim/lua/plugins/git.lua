-- Git UI
-- diffview.nvim: VS Code-style side-by-side diffs + changed-files panel
-- lazygit: full TUI for staging / committing in a floating terminal
--
-- Keymaps:
--   <leader>gd  open diff view (all working-tree changes)
--   <leader>gh  file history (log for current file)
--   <leader>gD  close diff view
--   <leader>gg  open lazygit (stage, commit, push, branch, etc.)

local gh = require('config.pack').gh

-- diffview.nvim — side-by-side diffs with file panel (like VS Code SCM)
vim.pack.add { gh 'sindrets/diffview.nvim' }
require('diffview').setup {
  enhanced_diff_hl = true, -- richer diff highlights
  view = {
    default = { layout = 'diff2_horizontal' }, -- side-by-side
    merge_tool = { layout = 'diff3_horizontal', disable_diagnostics = true },
  },
}

vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>',        { desc = '[G]it [D]iff view' })
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = '[G]it file [H]istory' })
vim.keymap.set('n', '<leader>gD', '<cmd>DiffviewClose<cr>',       { desc = '[G]it close [D]iff' })

-- lazygit floating terminal (binary installed by mise)
vim.keymap.set('n', '<leader>gg', function()
  if vim.fn.executable 'lazygit' == 0 then
    vim.notify('lazygit not found in PATH', vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.95),
    height = math.floor(vim.o.lines * 0.90),
    row = math.floor(vim.o.lines * 0.05),
    col = math.floor(vim.o.columns * 0.025),
    style = 'minimal',
    border = 'rounded',
  })
  vim.fn.termopen('lazygit', {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end,
  })
  vim.cmd 'startinsert'
end, { desc = '[G]it lazygit' })
