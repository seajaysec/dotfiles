local flag = vim.fs.joinpath(vim.fn.stdpath('data'), 'dotfiles-nvim-welcome-once')

local function show_once_notify()
  if vim.uv.fs_stat(flag) then
    return
  end
  local f = io.open(flag, 'w')
  if f then
    f:close()
  end
  vim.defer_fn(function()
    vim.notify(
      table.concat({
        'Dotfiles nvim is active.',
        'First time: type : Lazy sync Enter (wait). File browser: press - . Cheat sheet: F1',
      }, ' '),
      vim.log.levels.INFO,
      { title = 'nvim', timeout = 25000 }
    )
  end, 2000)
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = show_once_notify,
})
