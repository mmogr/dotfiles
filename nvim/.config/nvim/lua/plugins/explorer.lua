-- File explorer (neo-tree)
-- Sidebar file tree with git decorations, like VS Code's explorer
-- Toggle: <leader>e  |  Reveal current file: <leader>E
-- Inside the tree: a=new  r=rename  d=delete  y=copy  x=cut  p=paste  ?=help

local gh = require('config.pack').gh

vim.pack.add {
  gh 'nvim-neo-tree/neo-tree.nvim',
  gh 'MunifTanjim/nui.nvim',   -- UI dependency for neo-tree
  gh 'nvim-lua/plenary.nvim',  -- used by neo-tree for async fs operations
}

require('neo-tree').setup {
  close_if_last_window = true,
  window = { width = 30 },
  filesystem = {
    follow_current_file = { enabled = true }, -- auto-reveal open file in tree
    hide_dotfiles = false,
    filtered_items = {
      visible = false,
      hide_gitignored = true,
    },
  },
  default_component_configs = {
    git_status = {
      symbols = {
        added     = vim.g.have_nerd_font and '' or 'A',
        modified  = vim.g.have_nerd_font and '' or 'M',
        deleted   = vim.g.have_nerd_font and '✖' or 'D',
        renamed   = vim.g.have_nerd_font and '' or 'R',
        untracked = vim.g.have_nerd_font and '' or '?',
        ignored   = vim.g.have_nerd_font and '' or 'I',
        unstaged  = vim.g.have_nerd_font and '󰄱' or 'U',
        staged    = vim.g.have_nerd_font and '' or 'S',
        conflict  = vim.g.have_nerd_font and '' or 'C',
      },
    },
  },
}

vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<cr>', { desc = 'Toggle file [E]xplorer' })
vim.keymap.set('n', '<leader>E', '<cmd>Neotree reveal<cr>', { desc = 'Reveal file in [E]xplorer' })
