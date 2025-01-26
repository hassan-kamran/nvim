-- Basic Settings
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.fileformat = "unix"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.wrap = true
opt.cursorline = true
opt.updatetime = 250
opt.signcolumn = "yes:1"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.timeoutlen = 300
opt.laststatus = 3
opt.splitkeep = "screen"
opt.undofile = true
opt.swapfile = false
opt.completeopt = "menu,menuone,noselect"

-- Tabs/Indents
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable language providers except Python
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.python3_host_prog = ".venv/bin/python"

-- Plugin Manager: Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- Catppuccin colorscheme with priority
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
    },
    -- add other plugins here
  },
  install = { 
    colorscheme = { "catppuccin" }, 
  },
  checker = { enabled = true },
})

-- Apply colorscheme after setup
vim.cmd.colorscheme("catppuccin")
