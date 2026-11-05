vim.opt.termguicolors = true
vim.cmd.syntax('on')

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Dracula Pro (pack/themes/start/dracula_pro). Variants: dracula_pro_alucard, …
vim.g.dracula_colorterm = 0
vim.cmd.colorscheme('dracula_pro')

require('config.options')
require('config.lazy')
require('config.keymaps')
require('config.cheat')
require('config.welcome')
