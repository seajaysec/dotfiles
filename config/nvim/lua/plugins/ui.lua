return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-mini/mini.icons' },
    opts = {
      options = {
        theme = 'auto',
        icons_enabled = true,
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'modern',
      spec = {
        {
          '<leader>e',
          group = 'explorer',
        },
        { '-', desc = 'File browser (Telescope, here)' },
        { '<leader>em', desc = 'File browser (buffer dir)' },
        { '<leader>ee', desc = 'File browser (buffer dir)' },
        { '<leader>ef', desc = 'File browser (cwd)' },
        { '<leader>es', desc = 'Oil sidebar + preview (here)' },
        { '<leader>eS', desc = 'Oil sidebar + preview (cwd)' },
        { '<leader>f', group = 'find' },
        {
          '<leader>a',
          group = 'agentic',
        },
        { '<leader>ad', desc = 'Agentic: line diagnostics' },
        { '<leader>aD', desc = 'Agentic: buffer diagnostics' },
        { '<leader>cm', desc = 'Mason' },
      },
    },
  },
}
