-- Formatting (conform.nvim)
-- conform.nvim setup and keymap

local gh = require('config.pack').gh

-- [[ Formatting ]]
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Filetypes formatted on save
    local enabled_filetypes = {
      rust = true,
      javascript = true,
      typescript = true,
      typescriptreact = true,
      javascriptreact = true,
    }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 500 }
    else
      return nil
    end
  end,
  default_format_opts = {
    lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
  },
  -- External formatters per filetype
  formatters_by_ft = {
    rust = { 'rustfmt' },
    javascript = { 'prettier', stop_after_first = true },
    typescript = { 'prettier', stop_after_first = true },
    typescriptreact = { 'prettier', stop_after_first = true },
    javascriptreact = { 'prettier', stop_after_first = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
