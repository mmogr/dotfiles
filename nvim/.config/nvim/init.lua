-- Neovim configuration. Needs Neovim 0.12 or newer (vim.pack).
--
-- Started from kickstart.nvim and still follows its order: core settings
-- first, then one section per group of plugins. Plugins are installed by the
-- built-in vim.pack; their revisions are pinned in nvim-pack-lock.json.
--
--   :lua vim.pack.update()                          update plugins
--   :lua vim.pack.update(nil, { offline = true })   inspect plugin state
--   :Mason                                          LSP servers and tools
--   :checkhealth                                    diagnose a broken setup
--   <space>sh / <space>sk                           search help / keymaps
--
-- This file only sets the load order. The configuration is in lua/:
--
--   lua/config/    core settings that need no plugin, and the vim.pack build hooks
--   lua/plugins/   one file per group of plugins; each installs and configures its own

-- Enable faster startup by caching compiled Lua modules
vim.loader.enable()

-- lua/ is a separate link when this config is stowed file by file, so a checkout
-- that gained it needs `just stow-all` once. Say so instead of failing in require.
if not vim.uv.fs_stat(vim.fn.stdpath 'config' .. '/lua/config/options.lua') then
  vim.notify('nvim config: lua/ is not linked into ' .. vim.fn.stdpath 'config' .. ' — run `just stow-all` in the dotfiles repo', vim.log.levels.ERROR)
  return
end

-- options sets the leader keys, which must happen before any plugin loads.
-- pack registers the build hooks, which must exist before any plugin installs.
require 'config.options'
require 'config.keymaps'
require 'config.diagnostics'
require 'config.autocmds'
require 'config.pack'

-- The order the sections had in the single-file config. ui is first so the
-- colorscheme is set before anything else draws.
require 'plugins.ui'
require 'plugins.explorer'
require 'plugins.git'
require 'plugins.avante'
require 'plugins.terminal'
require 'plugins.telescope'
require 'plugins.lsp'
require 'plugins.java'
require 'plugins.format'
require 'plugins.completion'
require 'plugins.treesitter'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
