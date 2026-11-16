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

-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = true

  -- [[ Options ]]
  --  See `:help vim.o` and `:help option-list`

  -- Make line numbers default
  vim.o.number = true

  -- Enable mouse mode (handy for resizing splits)
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Scheduled after `UiEnter` because setting it can increase startup time.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Show certain whitespace characters. See `:help 'list'` and `:help 'listchars'`.
  --  listchars is a table, hence `vim.opt` rather than `vim.o` (`:help lua-options`).
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true

  -- [[ Basic Keymaps ]]
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode with <Esc><Esc> as well as the built-in <C-\><C-n>.
  -- Not every terminal emulator or tmux setup passes the double escape through.
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- CTRL+<hjkl> to switch between windows. See `:help wincmd`
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight yanked text. See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('user-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER
-- vim.pack build hooks
-- ============================================================
do
  -- [[ vim.pack ]]
  -- Neovim's built-in plugin manager. See `:help vim.pack` and
  -- https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  -- Some plugins need a build step after they are installed or updated;
  -- the PackChanged autocommand below runs it.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- Run a plugin's build command after it is installed or updated.
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end

      if name == 'avante.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end
    end,
  })
end

---Full URL of a plugin hosted on GitHub.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- Detect and set indentation automatically
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Icons, only with a Nerd Font to draw them
  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  -- Git signs in the gutter, and utilities for managing changes. See `:help gitsigns`
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- Show pending keybinds
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme ]]
  -- `:Telescope colorscheme` lists the installed ones.
  vim.pack.add { gh 'folke/tokyonight.nvim' }
  ---@diagnostic disable-next-line: missing-fields
  require('tokyonight').setup {
    styles = {
      comments = { italic = false }, -- Disable italics in comments
    },
  }

  -- Other styles: 'tokyonight-storm', 'tokyonight-moon', 'tokyonight-day'
  vim.cmd.colorscheme 'tokyonight-night'

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  -- Statusline
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- Show the cursor location as LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end
end

-- ============================================================
-- SECTION 3.5: FILE EXPLORER (neo-tree)
-- Sidebar file tree with git decorations, like VS Code's explorer
-- Toggle: <leader>e  |  Reveal current file: <leader>E
-- Inside the tree: a=new  r=rename  d=delete  y=copy  x=cut  p=paste  ?=help
-- ============================================================
do
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
end

-- ============================================================
-- SECTION 3.7: GIT UI
-- diffview.nvim: VS Code-style side-by-side diffs + changed-files panel
-- lazygit: full TUI for staging / committing in a floating terminal
--
-- Keymaps:
--   <leader>gd  open diff view (all working-tree changes)
--   <leader>gh  file history (log for current file)
--   <leader>gD  close diff view
--   <leader>gg  open lazygit (stage, commit, push, branch, etc.)
-- ============================================================
do
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
end

-- ============================================================
-- SECTION 3.85: AGENTIC CODING (avante.nvim)
-- Cursor/VS Code agent-mode equivalent: the model reads files, proposes
-- inline diffs, you accept/reject hunks — all inside nvim.
--
-- Endpoints (probed at startup, first one that answers becomes the default):
--   gglib         local proxy at 127.0.0.1:8080 (gglib proxy); authenticated with
--                 `gglib config reveal proxy-api-key`
--   gglib_remote  a paired machine's proxy via `gglib remote join --port 8180`;
--                 authenticated with `gglib config reveal remote-pairing.api-key`.
--                 Override the URL with $GGLIB_REMOTE_URL if joined on another port.
--   Neither key is stored here: gglib holds them and prints them on request.
-- Model: auto-detected from /v1/models at startup; use <leader>a? to switch.
--        Image-generation models and text encoders are filtered out; reasoning
--        models are preferred. Falls back to 'gglib-default' if nothing answers.
--
-- PLAN / EXECUTE mode toggle (hot-swaps avante.config at runtime):
--   <leader>ap   PLAN MODE  — strips write/exec tools; model can only read,
--                              then writes a structured markdown plan.
--   <leader>ae   EXECUTE MODE — restores all tools; model may edit freely.
--                (Normal mode only; avante's default visual <leader>ae is unchanged.)
--
-- Standard keymaps (avante default <leader>a prefix):
--   <leader>aa   Ask avante (open sidebar + send prompt)
--   <leader>ar   Refresh / regenerate last response
--   <leader>af   Focus avante input box
--   <leader>a?   Switch model (picker)
--   <leader>an   New ask (fresh chat)
-- Inside diff view: <Tab>/<S-Tab> to cycle hunks, <CR> to accept, <BS> reject
--
-- Startup: if gglib is installed but no endpoint offers a chat model, a WARN notification
-- says why for each: not running, not joined, key rejected, or gglib's CLI has changed.
-- ============================================================
do
  -- render-markdown: pretty markdown in avante sidebar (and .md files)
  vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }
  require('render-markdown').setup { file_types = { 'markdown', 'Avante' } }

  -- avante.nvim — requires build step (Rust); runs automatically on install/update
  vim.pack.add { gh 'yetone/avante.nvim' }
  -- avante's run_python tool shells out to `docker run`. With no Docker daemon,
  -- point the docker CLI at the rootless podman socket (just podman::enable-socket).
  do
    local podman_sock = (vim.env.XDG_RUNTIME_DIR or '') .. '/podman/podman.sock'
    if not vim.env.DOCKER_HOST and not vim.uv.fs_stat '/var/run/docker.sock' and vim.uv.fs_stat(podman_sock) then
      vim.env.DOCKER_HOST = 'unix://' .. podman_sock
    end
  end

  local GGLIB_LOCAL_URL  = 'http://127.0.0.1:8080/v1'
  local GGLIB_REMOTE_URL = vim.env.GGLIB_REMOTE_URL or 'http://127.0.0.1:8180/v1'

  -- Fetch chat-capable models from a gglib /v1/models endpoint.
  -- Returns the models and a status for the startup warning: 'ok', 'down' (nothing
  -- listening), 'timeout', 'auth' (key rejected), or a description of anything else.
  -- The bearer key goes to curl on stdin (-H @-) so it never appears in argv.
  local function gglib_fetch_models(base_url, key)
    -- No -f: the HTTP status is appended to the body, so a 401 can be told from a dead port.
    local cmd = { 'curl', '-s', '--max-time', '1', '-w', '\n%{http_code}', base_url .. '/models' }
    if key then vim.list_extend(cmd, { '-H', '@-' }) end
    local ok, res = pcall(function()
      return vim.system(cmd, { text = true, stdin = key and ('Authorization: Bearer ' .. key) or nil }):wait()
    end)
    if not ok then return {}, 'curl could not be run' end
    if res.code == 7 then return {}, 'down' end
    if res.code == 28 then return {}, 'timeout' end
    if res.code ~= 0 then return {}, 'curl exit ' .. res.code end
    local body, http = (res.stdout or ''):match '^(.*)\n(%d+)%s*$'
    if http == '401' or http == '403' then return {}, 'auth' end
    if http ~= '200' then return {}, 'HTTP ' .. tostring(http) end
    local decoded, data = pcall(vim.json.decode, body)
    if not decoded or type(data) ~= 'table' or type(data.data) ~= 'table' then return {}, 'unreadable model list' end

    local reasoning, other = {}, {}
    for _, m in ipairs(data.data) do
      local caps = type(m.capabilities) == 'table' and m.capabilities or {}
      local is_chat = not vim.tbl_contains(caps, 'image_generation') and not m.id:lower():find 'encoder'
      if is_chat then table.insert(vim.tbl_contains(caps, 'reasoning') and reasoning or other, m.id) end
    end
    return vim.list_extend(reasoning, other), 'ok'
  end

  -- gglib prints a stored secret alone on stdout. The command has moved twice:
  -- `remote key --show`, then `config settings reveal` (0.29), now `config reveal` (0.37).
  local function gglib_key_cmd(name) return { 'gglib', 'config', 'reveal', name } end
  local GGLIB_LOCAL_KEY_CMD  = gglib_key_cmd 'proxy-api-key'          -- this machine's proxy
  local GGLIB_REMOTE_KEY_CMD = gglib_key_cmd 'remote-pairing.api-key' -- this device's key for the machine it joined

  -- The secret `cmd` prints; nil when gglib is missing, the command fails, or nothing is stored.
  -- gglib exits 1 when nothing is stored and 2 when it does not know the command. The
  -- second means its CLI has moved again, and comes back as a message for the startup warning.
  local function gglib_reveal(cmd)
    if vim.fn.executable 'gglib' == 0 then return nil end
    local res = vim.system(cmd, { text = true }):wait()
    if res.code == 2 then
      return nil, ("`%s` failed: gglib's CLI changed, update init.lua"):format(table.concat(cmd, ' '))
    end
    local key = res.code == 0 and vim.trim(res.stdout or '') or ''
    return key ~= '' and key or nil
  end

  local gglib_local_key, gglib_local_cli_err     = gglib_reveal(GGLIB_LOCAL_KEY_CMD)
  local gglib_remote_key, gglib_remote_cli_err   = gglib_reveal(GGLIB_REMOTE_KEY_CMD) -- no key when not paired
  local gglib_local_models, gglib_local_status   = gglib_fetch_models(GGLIB_LOCAL_URL, gglib_local_key)
  local gglib_remote_models, gglib_remote_status = {}, nil -- not probed without a key
  if gglib_remote_key then
    gglib_remote_models, gglib_remote_status = gglib_fetch_models(GGLIB_REMOTE_URL, gglib_remote_key)
  end

  local function gglib_provider(endpoint, api_key_name, models)
    return {
      __inherited_from   = 'openai',
      api_key_name       = api_key_name,
      endpoint           = endpoint,
      model              = models[1] or 'gglib-default',
      model_names        = vim.list_slice(models), -- copy: avante appends to it in place
      timeout            = 60000,
      extra_request_body = {
        temperature = 0,
        max_tokens  = 8192,
      },
    }
  end

  -- avante runs a `cmd:` key command once per session and reads stdout only
  local function gglib_api_key_name(cmd) return 'cmd:' .. table.concat(cmd, ' ') end

  -- model and model_names are populated dynamically from /v1/models at startup
  local gglib_providers = {
    -- gglib proxy: OpenAI-compatible, local only. It wants its key since gglib 0.37;
    -- with none stored (an older gglib) any placeholder is accepted.
    gglib = gglib_provider(
      GGLIB_LOCAL_URL,
      gglib_local_key and gglib_api_key_name(GGLIB_LOCAL_KEY_CMD) or 'cmd:echo sk-dummy',
      gglib_local_models
    ),
  }
  if gglib_remote_key then
    gglib_providers.gglib_remote = gglib_provider(GGLIB_REMOTE_URL, gglib_api_key_name(GGLIB_REMOTE_KEY_CMD), gglib_remote_models)
  end

  local gglib_default_provider = 'gglib'
  if #gglib_local_models == 0 and #gglib_remote_models > 0 then gglib_default_provider = 'gglib_remote' end

  require('avante').setup {
    provider  = gglib_default_provider,
    -- avante offers its built-in copilot provider in the model picker whenever a
    -- GitHub Copilot login exists (~/.config/github-copilot); Copilot isn't used
    providers = vim.tbl_extend('error', gglib_providers, { copilot = { hide_in_model_selector = true } }),
    behaviour = {
      auto_suggestions              = false, -- inline completions off (use blink.cmp)
      auto_approve_tool_permissions = true,  -- default: approve all (overridden in plan mode)
    },
    windows = {
      position = 'right',
      width    = 38,
      wrap     = true,
      -- show provider/model in the sidebar header; also stops avante announcing
      -- the restored model at startup (which triggered a hit-enter prompt)
      sidebar_header = { include_model = true },
    },
  }

  -- avante restores the last picked provider (~/.config/avante.nvim/config.json)
  -- over `provider` above; respect it unless that endpoint is down and another is up.
  local gglib_live = { gglib = gglib_local_models, gglib_remote = gglib_remote_models }
  local restored   = require('avante.config').provider
  if gglib_live[restored] and #gglib_live[restored] == 0 and #gglib_live[gglib_default_provider] > 0 then
    -- what avante.api.switch_provider does, minus its startup notice
    require('avante.config').override { provider = gglib_default_provider }
    require('avante.providers')[gglib_default_provider].setup()
  end

  -- ── Plan / Execute mode toggle ───────────────────────────────────────────
  -- All write, edit, create, delete, and exec tools are stripped from the
  -- model's context in plan mode — it cannot use them even if it tries.
  -- Execute mode restores the defaults set in setup() above.
  local PLAN_DISABLED_TOOLS = {
    -- file write / edit
    'str_replace', 'write_to_file', 'insert',         'undo_edit',
    'edit_file',   'create_file',   'write_global_file',
    -- filesystem mutation
    'move_path',   'copy_path',     'delete_path',     'create_dir',
    -- code / command execution (all known names; hallucinated names also listed)
    'bash',        'python',        'run_python',      'run_code',
    'execute',
    -- external I/O (network)
    'web_search',  'fetch',
    -- git mutation
    'git_commit',
    -- meta / orchestration
    'write_todos', 'dispatch_agent',
  }

  vim.keymap.set('n', '<leader>ap', function()
    require('avante.config').override {
      system_prompt  = 'You are in PLAN MODE. You may use read-only tools'
        .. ' (read_file, view, glob, grep, ls, git_diff, think, etc.) to investigate'
        .. ' the codebase, but you are STRICTLY FORBIDDEN from using any write, edit,'
        .. ' create, delete, bash, or git-commit tools. Do NOT produce diffs or apply'
        .. ' changes. Only output a clear, structured markdown plan.'
        .. ' CRITICAL: You do not have a code interpreter. DO NOT attempt to write,'
        .. ' generate, or execute any code using tools. You are strictly a text-based'
        .. ' analyzer. Your ONLY output must be a Markdown text plan.'
        .. ' EXCEPTION: You are allowed to ask questions BEFORE writing the plan'
        .. ' ONLY if the task is severely ambiguous. If you must ask, do not ask'
        .. ' broad questions. Use your read tools to investigate the codebase first,'
        .. ' and formulate highly specific, targeted questions based on what you found.'
        .. ' Wait for the user\'s response before continuing.',
      disabled_tools = PLAN_DISABLED_TOOLS,
      behaviour      = { auto_approve_tool_permissions = false },
    }
    vim.notify('[avante] PLAN MODE — read-only tools only', vim.log.levels.INFO, { title = 'avante' })
    require('avante.api').ask()
  end, { desc = '[A]vante [P]lan mode (read-only)' })

  vim.keymap.set('n', '<leader>ae', function()
    require('avante.config').override {
      system_prompt  = nil,
      disabled_tools = {},
      behaviour      = { auto_approve_tool_permissions = true },
    }
    vim.notify('[avante] EXECUTE MODE — all tools enabled', vim.log.levels.INFO, { title = 'avante' })
    require('avante.api').ask()
  end, { desc = '[A]vante [E]xecute mode (all tools)' })

  -- Warn at startup if gglib is installed but the probe above found no chat model,
  -- saying what went wrong at each endpoint. A key command gglib no longer knows is
  -- always reported, even when the other endpoint works: this file is out of date.
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      if vim.fn.executable 'gglib' == 0 then return end
      local have_model = #gglib_local_models > 0 or #gglib_remote_models > 0
      local says = { ok = 'has no chat models', timeout = 'did not answer within 1s' }
      local endpoints = {
        {
          what = 'local proxy', status = gglib_local_status, cli_err = gglib_local_cli_err,
          says = { down = 'is not running (gglib proxy)', auth = 'rejected its key' },
        },
        {
          what = 'remote', status = gglib_remote_status, cli_err = gglib_remote_cli_err,
          says = { down = 'is not joined (gglib remote join)', auth = "rejected this device's key (pair again)" },
        },
      }
      local problems = {}
      for _, e in ipairs(endpoints) do
        if e.cli_err then
          problems[#problems + 1] = e.cli_err
        elseif not have_model and e.status then
          problems[#problems + 1] = e.what .. ' ' .. (e.says[e.status] or says[e.status] or ('failed: ' .. e.status))
        end
      end
      if #problems == 0 then return end
      vim.defer_fn(function()
        vim.notify('[gglib] ' .. table.concat(problems, '; '), vim.log.levels.WARN, { title = 'gglib' })
      end, 500)
    end,
  })
end

-- ============================================================
-- SECTION 3.9: INTEGRATED TERMINAL (toggleterm)
-- Persistent terminal that survives toggling — run cargo, npm, etc.
-- without leaving nvim.
--
-- Keymaps:
--   <C-\>       toggle horizontal terminal (bottom panel, like VS Code)
--   <leader>tf  toggle floating terminal
--   <leader>tv  toggle vertical terminal (side panel)
-- Inside the terminal:
--   <C-\><C-n>  back to normal mode (built-in nvim — works in any term)
--   <C-\>       toggle closed (works in terminal mode too)
-- ============================================================
do
  vim.pack.add { gh 'akinsho/toggleterm.nvim' }
  require('toggleterm').setup {
    size = function(term)
      if term.direction == 'horizontal' then return 15
      elseif term.direction == 'vertical' then return math.floor(vim.o.columns * 0.38)
      end
    end,
    open_mapping = [[<c-\>]],
    direction = 'horizontal',
    shade_terminals = false,
    persist_mode = true, -- remember insert/normal mode per terminal
  }

  vim.keymap.set({ 'n', 't' }, '<leader>tf', '<cmd>ToggleTerm direction=float<cr>',    { desc = '[T]erminal [F]loating' })
  vim.keymap.set({ 'n', 't' }, '<leader>tv', '<cmd>ToggleTerm direction=vertical<cr>', { desc = '[T]erminal [V]ertical' })

  -- Mouse wheel over a Claude Code terminal while it isn't in terminal mode
  -- (e.g. you're editing in another split): nvim would scroll the terminal
  -- buffer itself, dragging Claude's whole screen, input box included, up the
  -- window. Forward the wheel to Claude as an SGR mouse event instead so its
  -- own transcript scrolls. Claude's fullscreen TUI turns on SGR mouse mode
  -- (?1006); in terminal mode nvim already forwards the wheel natively.
  local claude_cache = {} -- bufnr -> { checked_at, is_claude }

  local function runs_claude(pid, depth)
    if depth > 3 then return false end
    for _, child in ipairs(vim.api.nvim_get_proc_children(pid)) do
      local proc = vim.api.nvim_get_proc(child)
      if (proc and proc.name == 'claude') or runs_claude(child, depth + 1) then return true end
    end
    return false
  end

  local function is_claude_term(buf)
    if vim.bo[buf].buftype ~= 'terminal' then return false end
    -- nvim_get_proc shells out to ps (~5ms), so cache the answer briefly
    local cached = claude_cache[buf]
    local now = vim.uv.now()
    if cached and now - cached[1] < 3000 then return cached[2] end
    local ok, pid = pcall(vim.fn.jobpid, vim.bo[buf].channel)
    local proc = ok and vim.api.nvim_get_proc(pid)
    local result = ok and ((proc and proc.name == 'claude') or runs_claude(pid, 1)) or false
    claude_cache[buf] = { now, result }
    return result
  end

  local function wheel(dir)
    local key = vim.keycode(dir == 'up' and '<ScrollWheelUp>' or '<ScrollWheelDown>')
    return function()
      local pos = vim.fn.getmousepos()
      local buf = pos.winid ~= 0 and vim.api.nvim_win_get_buf(pos.winid)
      if not buf or not is_claude_term(buf) then
        vim.api.nvim_feedkeys(key, 'n', false)
        return
      end
      -- snap back to the live screen in case the buffer was already scrolled
      vim.api.nvim_win_call(pos.winid, function() vim.cmd 'normal! G' end)
      local button = dir == 'up' and 64 or 65
      vim.api.nvim_chan_send(vim.bo[buf].channel, ('\27[<%d;%d;%dM'):format(button, math.max(pos.wincol, 1), math.max(pos.winrow, 1)))
    end
  end

  vim.keymap.set('n', '<ScrollWheelUp>', wheel 'up', { desc = 'Scroll (forwarded to Claude Code terminals)' })
  vim.keymap.set('n', '<ScrollWheelDown>', wheel 'down', { desc = 'Scroll (forwarded to Claude Code terminals)' })
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy finder (files, lsp, etc) ]]
  -- Inside any Telescope picker, <c-/> (insert mode) or ? (normal mode) lists
  -- that picker's keymaps.

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  -- See `:help telescope.builtin`
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- See `:help telescope.builtin.live_grep()` for the available keys
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP ]]
  -- Language servers are external programs; mason installs the ones listed in
  -- `servers` below. See `:help lsp-vs-treesitter` for how LSP and treesitter differ.

  -- Useful status updates for LSP.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  -- Runs each time a language server attaches to a buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
    callback = function(event)
      -- Buffer-local mapping whose description gets an "LSP: " prefix
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Language servers to enable; mason installs each one.
  --  See `:help lsp-config` for the keys a server accepts
  ---@type table<string, vim.lsp.Config>
  local servers = {
    rust_analyzer = {},
    ts_ls = {},

    stylua = {}, -- Used to format Lua code

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Install the servers above plus the tools below. `:Mason` shows their
  -- status and installs others (g? for help in that window).
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- rustfmt is NOT a Mason package — it ships with Rust via rustup.
    -- conform.nvim calls the system rustfmt binary directly.
    'prettier',
    'eslint_d',
    'jdtls', -- Java language server (managed separately via nvim-jdtls below)
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 5.5: JAVA (nvim-jdtls)
-- Uses nvim-jdtls instead of lspconfig for per-project workspace
-- isolation and IntelliJ-level features (organize imports, code gen, DAP)
-- ============================================================
do
  vim.pack.add { gh 'mfussenegger/nvim-jdtls' }

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'java',
    callback = function()
      local ok, jdtls = pcall(require, 'jdtls')
      if not ok then return end

      local ok_mason, registry = pcall(require, 'mason-registry')
      if not ok_mason or not registry.is_installed 'jdtls' then
        vim.notify('jdtls not installed — run :MasonInstall jdtls', vim.log.levels.WARN)
        return
      end

      local install_path = registry.get_package('jdtls'):get_install_path()
      local launcher = vim.fn.glob(install_path .. '/plugins/org.eclipse.equinox.launcher_*.jar', true)
      local os_config = vim.fn.has 'mac' == 1 and 'mac' or 'linux'

      -- Isolated workspace per project root (prevents cross-project contamination)
      local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
      local root_dir = jdtls.setup.find_root(root_markers) or vim.fn.getcwd()
      local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':t')

      jdtls.start_or_attach {
        cmd = {
          'java',
          '-Declipse.application=org.eclipse.jdt.ls.core.id1',
          '-Dosgi.bundles.defaultStartLevel=4',
          '-Declipse.product=org.eclipse.jdt.ls.core.product',
          '-Dlog.protocol=true',
          '-Dlog.level=ALL',
          '-Xmx2g',
          '--add-modules=ALL-SYSTEM',
          '--add-opens', 'java.base/java.util=ALL-UNNAMED',
          '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
          '-jar', launcher,
          '-configuration', install_path .. '/config_' .. os_config,
          '-data', workspace_dir,
        },
        root_dir = root_dir,
        settings = {
          java = {
            signatureHelp = { enabled = true },
            completion = { favoriteStaticMembers = {
              'org.junit.Assert.*',
              'org.junit.jupiter.api.Assertions.*',
              'org.mockito.Mockito.*',
            } },
            sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
            codeGeneration = {
              toString = { template = '${object.className}{${member.name()}=${member.value}, }' },
              useBlocks = true,
            },
          },
        },
        init_options = { bundles = {} },
        -- Java-specific keymaps (active only in Java buffers)
        on_attach = function(_, bufnr)
          local map = function(keys, fn, desc)
            vim.keymap.set('n', keys, fn, { buffer = bufnr, desc = 'Java: ' .. desc })
          end
          map('<leader>co', jdtls.organize_imports, 'Organize imports')
          map('<leader>cv', jdtls.extract_variable, 'Extract variable')
          map('<leader>cm', jdtls.extract_method, 'Extract method')
          -- nvim-jdtls has no generate function: jdtls offers these as source.generate.* code actions
          map('<leader>cg', function() vim.lsp.buf.code_action { context = { only = { 'source.generate' } } } end, 'Generate (constructors / getters / setters)')
        end,
      }
    end,
  })
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
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
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- Pinned to a version range of git tags. See `:help vim.version.range()`
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- 'default' for mappings similar to built-in completion (`:help ins-completion`)
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'default',

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- Tracks the main branch
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'rust', 'typescript', 'javascript', 'tsx', 'toml', 'json' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
