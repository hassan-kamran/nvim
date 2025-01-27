-- init.lua
-- LuaRocks Paths
------------------
pcall(function()
  local lua_version = _VERSION:match("%d+%.%d+")
  local home = os.getenv("HOME")

  package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/" .. lua_version .. "/?.lua"
  package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/" .. lua_version .. "/?/init.lua"
  package.cpath = package.cpath .. ";" .. home .. "/.luarocks/lib/lua/" .. lua_version .. "/?.so"
end)

-- Basic Settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Editor Behavior
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.signcolumn = "yes:1"
opt.splitbelow = true
opt.splitright = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true

-- Formatting
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- Python Configuration
vim.g.python3_host_prog = ".venv/bin/python"
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

-- Plugin Management (Lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-macchiato")
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
})

-- LSP Setup
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Ruff LSP Configuration (Formatting + Linting)
lspconfig.ruff.setup({
  capabilities = capabilities,
  init_options = {
    settings = {
      args = {},
      lint = {
        enable = true,
        select = { "ALL" },
        ignore = {},
        preview = true,
      },
      format = {
        enable = true,
        args = {},
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Format on save with Ruff only
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({
          async = false,
          filter = function(client)
            return client.name == "ruff"
          end
        })
      end
    })
  end
})

-- Pyright Configuration (Type checking only)
lspconfig.pyright.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- Disable Pyright formatting capabilities
    client.server_capabilities.documentFormattingProvider = false
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- Autocompletion Setup
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
})

-- Key Mappings
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })

-- Quality of Life Improvements
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
}
