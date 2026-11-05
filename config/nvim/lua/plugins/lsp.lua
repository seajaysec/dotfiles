return {
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      {
        'mason-org/mason.nvim',
        lazy = false,
        opts = {},
      },
      {
        'neovim/nvim-lspconfig',
        lazy = false,
      },
    },
    lazy = false,
    config = function()
      require('mason').setup()
      vim.keymap.set('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })
      local lspconfig = require('lspconfig')
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls' },
        handlers = {
          function(server_name)
            lspconfig[server_name].setup({})
          end,
          ['lua_ls'] = function()
            lspconfig.lua_ls.setup({
              settings = {
                Lua = {
                  runtime = { version = 'LuaJIT' },
                  workspace = {
                    checkThirdParty = false,
                    library = {
                      vim.env.VIMRUNTIME .. '/lua',
                      '${3rd}/luv/library',
                    },
                  },
                },
              },
            })
          end,
        },
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local buf = ev.buf
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf, desc = 'LSP definition' })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf, desc = 'LSP hover' })
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = buf, desc = 'LSP rename' })
        end,
      })
    end,
  },
}
