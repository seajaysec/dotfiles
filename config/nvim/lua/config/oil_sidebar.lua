local api = vim.api

local M = {}

local sidebar_win ---@type integer|nil

function M.get_win()
  return sidebar_win
end

local function close_preview()
  local ok, util = pcall(require, 'oil.util')
  if not ok then
    return
  end
  local pw = util.get_preview_win()
  if pw and api.nvim_win_is_valid(pw) then
    api.nvim_win_close(pw, true)
  end
end

--- Toggle fixed left column: oil listing + live preview split (preview sits between sidebar and editor).
---@param opts? { dir?: string, width?: integer }
function M.toggle(opts)
  opts = opts or {}
  if sidebar_win and api.nvim_win_is_valid(sidebar_win) then
    close_preview()
    api.nvim_win_close(sidebar_win, true)
    sidebar_win = nil
    return
  end

  local dir = opts.dir or vim.fn.expand('%:p:h')
  local width = opts.width or 36

  vim.cmd('leftabove vertical split')
  vim.cmd('vertical resize ' .. width)
  vim.wo.winfixwidth = true
  sidebar_win = api.nvim_get_current_win()

  api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(sidebar_win),
    once = true,
    callback = function()
      sidebar_win = nil
      close_preview()
    end,
  })

  require('oil').open(dir, {
    preview = { vertical = true },
  })
end

return M
