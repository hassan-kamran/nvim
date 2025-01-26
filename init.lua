--------------------------------------------------------------------------------
-- init.lua
--------------------------------------------------------------------------------

------------------
-- LuaRocks Paths
------------------
pcall(function()
	local lua_version = _VERSION:match("%d+%.%d+")
	local home = os.getenv("HOME")

	package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/" .. lua_version .. "/?.lua"
	package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/" .. lua_version .. "/?/init.lua"
	package.cpath = package.cpath .. ";" .. home .. "/.luarocks/lib/lua/" .. lua_version .. "/?.so"
end)

----------------------------------------------------
-- Basic Settings
----------------------------------------------------
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.fileformat = "unix"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.wrap = false
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

----------------------------------------------------
-- Tabs/Indents
----------------------------------------------------
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

----------------------------------------------------
-- Leader Key
----------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

----------------------------------------------------
-- Python Virtual Environment
----------------------------------------------------
local function setup_venv()
	local venv_path = vim.fn.stdpath("config") .. "/neovim-venv"
	local python_executable = venv_path .. "/bin/python"

	if vim.fn.executable("python3") == 0 then
		vim.notify("Python3 not found!", vim.log.levels.WARN)
		return
	end

	if vim.fn.isdirectory(venv_path) == 0 then
		local success = pcall(vim.fn.system, { "python3", "-m", "venv", venv_path })
		if not success then
			vim.notify("Failed to create Python venv!", vim.log.levels.ERROR)
			return
		end
	end

	vim.g.python3_host_prog = python_executable
	vim.fn.system({ python_executable, "-m", "pip", "install", "--quiet", "pynvim" })
end
setup_venv()

----------------------------------------------------
-- Plugin Manager: Lazy.nvim
----------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- Plugin Configuration
--------------------------------------------------------------------------------
require("lazy").setup({
	-- Colorscheme
	{
		"catppuccin/nvim",
		priority = 1000,
		config = function()
			require("catppuccin").setup({ flavour = "mocha" })
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- GitHub Copilot
	{
		"github/copilot.vim",
		event = "InsertEnter",
		config = function()
			vim.g.copilot_no_tab_map = true
			vim.g.copilot_assume_mapped = true
			vim.api.nvim_set_keymap("i", "<C-j>", "copilot#Accept('<CR>')", {
				silent = true,
				expr = true,
				script = true,
				replace_keycodes = false,
			})
		end,
	},

	-- LSP & Formatting
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({ automatic_installation = true })

			require("mason-tool-installer").setup({
				ensure_installed = {
					"pyright",
					"ruff-lsp",
					"html",
					"cssls",
					"ts_ls",
					"emmet-ls",
					"black",
					"prettierd",
					"stylua",
					"eslint_d",
				},
			})
		end,
	},

	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		event = "BufReadPre",
		config = function()
			local lsp = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				local bufopts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
			end

			-- TypeScript/JavaScript
			lsp.ts_ls.setup({
				capabilities = capabilities,
				on_attach = on_attach,
				root_dir = lsp.util.root_pattern("package.json", "tsconfig.json", ".git"),
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
						},
					},
				},
			})

			-- Python
			lsp.pyright.setup({
				capabilities = capabilities,
				on_attach = on_attach,
				settings = { python = { analysis = { typeCheckingMode = "basic" } } },
			})

			-- HTML/CSS
			lsp.html.setup({ capabilities = capabilities, on_attach = on_attach })
			lsp.cssls.setup({ capabilities = capabilities, on_attach = on_attach })
			lsp.emmet_ls.setup({
				capabilities = capabilities,
				on_attach = on_attach,
				filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
			})
		end,
	},

	-- Formatting & Linting
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					python = { "black", "ruff" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					javascriptreact = { "prettierd" },
					typescriptreact = { "prettierd" },
					html = { "prettierd" },
					css = { "prettierd" },
					lua = { "stylua" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"python",
					"lua",
					"vim",
					"html",
					"css",
					"javascript",
					"typescript",
					"tsx",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		},
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"github/copilot.vim",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),

					["<C-j>"] = cmp.mapping(function(fallback)
						if require("copilot.suggestion").is_visible() then
							require("copilot.suggestion").accept()
						else
							fallback()
						end
					end, { "i" }),

					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "copilot" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}),
			})
		end,
	},

	-- File Explorer
	{
		"nvim-tree/nvim-tree.lua",
		keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File Explorer" } },
		config = function()
			require("nvim-tree").setup({
				view = { width = 35 },
				filters = { dotfiles = true },
			})
		end,
	},
})

--------------------------------------------------------------------------------
-- Additional Configuration
--------------------------------------------------------------------------------

-- Keymaps
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format File" })
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Diagnostic Configuration
vim.diagnostic.config({
	virtual_text = { prefix = "●" },
	float = { border = "rounded" },
})

-- Filetype-specific settings
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "html", "javascript", "typescript", "css" },
	callback = function()
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
	end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
