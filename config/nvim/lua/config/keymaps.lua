vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Focus window left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Focus window down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Focus window up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Focus window right' })
