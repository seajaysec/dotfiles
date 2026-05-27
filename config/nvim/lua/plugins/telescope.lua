local function file_browser_here()
  require('telescope').extensions.file_browser.file_browser({
    path = vim.fn.expand('%:p:h'),
    select_buffer = true,
  })
end

local function file_browser_cwd()
  require('telescope').extensions.file_browser.file_browser({
    cwd = vim.fn.getcwd(),
  })
end

return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
    },
    keys = {
      {
        '<leader>ff',
        function()
          require('telescope.builtin').find_files()
        end,
        desc = 'Find files',
      },
      {
        '<leader>fg',
        function()
          require('telescope.builtin').live_grep()
        end,
        desc = 'Live grep',
      },
      {
        '<leader>fb',
        function()
          require('telescope.builtin').buffers()
        end,
        desc = 'Buffers',
      },
      {
        '<leader>fh',
        function()
          require('telescope.builtin').help_tags()
        end,
        desc = 'Help tags',
      },
      {
        '<leader>ee',
        file_browser_here,
        desc = 'File browser (buffer dir)',
      },
      {
        '<leader>ef',
        file_browser_cwd,
        desc = 'File browser (cwd)',
      },
      {
        '<leader>em',
        file_browser_here,
        desc = 'File browser (here)',
      },
      {
        '-',
        file_browser_here,
        desc = 'File browser (here)',
      },
    },
    opts = {
      defaults = {
        preview = true,
        sorting_strategy = 'ascending',
        layout_strategy = 'horizontal',
        layout_config = {
          prompt_position = 'top',
          preview_width = 0.55,
        },
      },
      extensions = {
        file_browser = {
          hijack_netrw = true,
          respect_gitignore = vim.fn.executable('fd') == 1,
          hidden = { file_browser = false, folder_browser = false },
        },
      },
    },
    config = function(_, opts)
      local actions = require('telescope.actions')
      local fb_actions = require('telescope._extensions.file_browser.actions')
      opts.extensions.file_browser.mappings = {
        ['n'] = {
          ['l'] = actions.select_default,
          ['h'] = fb_actions.goto_parent_dir,
          ['f'] = false,
        },
      }
      require('telescope').setup(opts)
      require('telescope').load_extension('file_browser')
    end,
  },
}
