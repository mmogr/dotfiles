-- Agentic coding (avante.nvim)
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

local gh = require('config.pack').gh

-- render-markdown: pretty markdown in avante sidebar (and .md files)
vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }
require('render-markdown').setup { file_types = { 'markdown', 'Avante' } }

-- avante.nvim, on tagged releases. Its native libraries are downloaded for the
-- checked-out release on install/update (the PackChanged hook in config/pack.lua).
vim.pack.add {
  gh 'MunifTanjim/nui.nvim',
  gh 'ColinKennedy/mega.logging',  -- required by mega.cmdparse
  gh 'ColinKennedy/mega.cmdparse', -- parses avante's : commands
  { src = gh 'avante-corp/avante.nvim', version = vim.version.range '0.*' },
}
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
    return nil, ("`%s` failed: gglib's CLI changed, update lua/plugins/avante.lua"):format(table.concat(cmd, ' '))
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
  -- external I/O (network); see plan_disabled_tools() for the other web_search_* names
  'web_search',  'web_search_tavily', 'fetch',
  -- git mutation
  'git_commit',
  -- meta / orchestration
  'write_todos', 'dispatch_agent',
}

-- Since avante 0.5 a web search tool is named after its engine: web_search_tavily
-- is built in, and one added through custom_tools is web_search_<engine>. Add
-- whichever are registered, so plan mode keeps the network off for all of them.
local function plan_disabled_tools()
  local disabled = vim.list_slice(PLAN_DISABLED_TOOLS)
  local ok, tools = pcall(function() return require('avante.llm_tools').get_tools('', {}, false) end)
  for _, tool in ipairs(ok and tools or {}) do
    if type(tool.name) == 'string' and tool.name:find '^web_search' and not vim.tbl_contains(disabled, tool.name) then
      table.insert(disabled, tool.name)
    end
  end
  return disabled
end

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
    disabled_tools = plan_disabled_tools(),
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
