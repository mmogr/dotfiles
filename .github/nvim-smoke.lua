-- CI smoke test for the Neovim config. Run after startup:
--
--   nvim --headless -c 'luafile .github/nvim-smoke.lua'
--
-- On a runner this is the first start ever, so it also covers installing every
-- plugin at the revision in nvim-pack-lock.json. It quits with status 1 and
-- prints what is wrong if the config did not load to the end, a plugin is
-- missing or at another revision, or startup reported an error.

local problems = {}
local function fail(msg) problems[#problems + 1] = msg end

-- The config ran to the end: these come from its first and last parts.
if vim.g.mapleader ~= ' ' then fail 'leader is not set: the config did not load' end
if vim.fn.maparg('<leader>sf', 'n') == '' then fail '<leader>sf is not mapped: Telescope did not load' end
if not package.loaded['nvim-treesitter'] then fail 'nvim-treesitter is not loaded: the config stopped early' end

-- avante's native libraries were downloaded by the PackChanged build hook.
for _, p in ipairs(vim.pack.get { 'avante.nvim' }) do
  if #vim.fn.glob(p.path .. '/lua/avante_templates.*', true, true) == 0 then fail 'avante has no native libraries: its build step did not run' end
end

-- Every plugin in the lock file is installed at its pinned revision, and nothing else is.
local lock_path = vim.fn.stdpath 'config' .. '/nvim-pack-lock.json'
local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), '\n')).plugins
-- The revision is read from the checkout itself, not from what vim.pack reports.
local installed = {}
for _, p in ipairs(vim.pack.get()) do
  installed[p.spec.name] = true
  local want = lock[p.spec.name]
  local head = vim.trim(vim.system({ 'git', '-C', p.path, 'rev-parse', 'HEAD' }, { text = true }):wait().stdout or '')
  if not want then
    fail(p.spec.name .. ' is installed but not in nvim-pack-lock.json')
  elseif want.rev ~= head then
    fail(('%s is checked out at %s, the lock file pins %s'):format(p.spec.name, head, want.rev))
  end
end
for name in pairs(lock) do
  if not installed[name] then fail(name .. ' is in nvim-pack-lock.json but was not installed') end
end

-- Nothing reported an error.
for line in vim.fn.execute('messages'):gmatch '[^\n]+' do
  if line:find '^E%d+:' or line:find '[Ee]rror' or line:find '[Ff]ailed' or line:find 'stack traceback' then fail('message: ' .. line) end
end

if #problems > 0 then
  io.stderr:write('nvim smoke test FAILED:\n  ' .. table.concat(problems, '\n  ') .. '\n\n:messages was:\n' .. vim.fn.execute 'messages' .. '\n')
  vim.cmd 'cquit 1'
end
io.stdout:write(('nvim smoke test passed: %d plugins at their pinned revisions\n'):format(vim.tbl_count(installed)))
vim.cmd 'qa!'
