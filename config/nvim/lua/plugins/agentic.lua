-- Agent chat via Agent Client Protocol (ACP). Requires Neovim 0.11+.
-- Default: Cursor (`cursor-agent acp`) — same auth as `cursor agent login`.
-- Other providers: https://github.com/carlos-algms/agentic.nvim
return {
  {
    'carlos-algms/agentic.nvim',
    lazy = false,
    dependencies = {
      {
        'hakonharnes/img-clip.nvim',
        lazy = false,
        opts = {},
      },
    },
    ---@type agentic.PartialUserConfig
    opts = {
      provider = 'cursor-acp',
      windows = {
        position = 'right',
        width = '40%',
      },
      diff_preview = {
        enabled = true,
        layout = 'split',
      },
    },
    keys = {
      {
        '<C-\\>',
        function()
          require('agentic').toggle()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'Toggle Agentic chat',
      },
      {
        "<C-'>",
        function()
          require('agentic').add_selection_or_file_to_context()
        end,
        mode = { 'n', 'v' },
        desc = 'Add file or selection to Agentic',
      },
      {
        '<C-,>',
        function()
          require('agentic').new_session()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'New Agentic session',
      },
      {
        '<A-i>r',
        function()
          require('agentic').restore_session()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'Agentic restore session',
        silent = true,
      },
      {
        '<leader>ad',
        function()
          require('agentic').add_current_line_diagnostics()
        end,
        mode = 'n',
        desc = 'Agentic: line diagnostics',
      },
      {
        '<leader>aD',
        function()
          require('agentic').add_buffer_diagnostics()
        end,
        mode = 'n',
        desc = 'Agentic: buffer diagnostics',
      },
    },
  },
}
