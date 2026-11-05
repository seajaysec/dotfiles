-- Pinned to `master`: the plugin's `main` branch is a rewrite targeting nvim-treesitter's new API.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        'lua',
        'vim',
        'vimdoc',
        'markdown',
        'markdown_inline',
      },
      auto_install = true,
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
  },
}
