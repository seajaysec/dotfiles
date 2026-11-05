return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {
      default_file_explorer = false,
      delete_to_trash = true,
      preview_win = {
        update_on_cursor_moved = true,
        preview_method = 'fast_scratch',
      },
      keymaps = {
        ['l'] = 'actions.select',
        ['h'] = 'actions.parent',
      },
    },
    config = function(_, opts)
      require('oil').setup(opts)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'oil',
        callback = function(ev)
          vim.keymap.set('n', 'q', function()
            local win = vim.api.nvim_get_current_win()
            local side = require('config.oil_sidebar').get_win()
            if side and win == side then
              require('config.oil_sidebar').toggle()
            else
              vim.cmd.close()
            end
          end, { buffer = ev.buf, desc = 'Close oil / sidebar' })
        end,
      })
    end,
    keys = {
      {
        '<leader>es',
        function()
          require('config.oil_sidebar').toggle({ dir = vim.fn.expand('%:p:h') })
        end,
        desc = 'File sidebar (here + preview)',
      },
      {
        '<leader>eS',
        function()
          require('config.oil_sidebar').toggle({ dir = vim.fn.getcwd() })
        end,
        desc = 'File sidebar (cwd + preview)',
      },
    },
  },
}
