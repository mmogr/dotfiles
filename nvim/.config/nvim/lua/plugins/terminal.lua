-- Integrated terminal (toggleterm)
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

local gh = require('config.pack').gh

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
