-- My nvim config, cutdown from nvim-lua/kickstart.nvim

-- ==================================================================================================== 
-- SECTION 1: Core
-- basic vim config
-- ==================================================================================================== 

do

    vim.loader.enable()
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    vim.g.have_nerd_font = true

    -- tabs as spaces
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.softtabstop = 4

    -- formatting
    vim.o.number = true
    vim.o.mouse = 'a'
    

    -- clipboard
    -- can increase startuptime, so setting it after UI
    vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

    vim.o.breakindent = true

    -- enable undo/redo after reopening file
    vim.o.undofile = true

    -- basic search
    vim.o.ignorecase = true
    vim.o.smartcase = true
    vim.o.signcolumn = 'yes'

    vim.o.updatetime = 250
    vim.o.timeoutlen = 300

    vim.o.splitright = true

    vim.o.splitbelow = true

    -- whitespace characters
    vim.o.list = true
    vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

    -- show substitutions in buffer
    vim.o.inccommand = 'nosplit'

    vim.o.cursorline = true
    vim.o.scrolloff = 10

    vim.o.confirm = true
end

-- ==================================================================================================== 
-- SECTION 2: keymaps and autocmds
-- ==================================================================================================== 

do 
    vim.keymap.set('n', '<ESC>', '<cmd>nohlsearch<CR>')
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
    -- alt keymap for visual block when ctrl v is stolen
    vim.keymap.set('n', '<leader>v', '<C-v>')

    -- default terminal exit is ctrl + \, ctrl + n which is hard to remember
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

    -- diagnostic config
    vim.diagnostic.config {
        update_in_insert = true,
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many'},
        underline = { severity = { min = vim.diagnostic.severity.WARN } },

        virtual_text = true, -- text shows at end of line
        virtual_lines = false,

        -- auto open the float so we can easily read the errors when jumping between them
        jump = {
            on_jump = function(_, bufnr)
                vim.diagnostic.open_float {
                    bufnr = bufnr,
                    score = 'cursor',
                    focus = false,
                }
            end,
        },

    }

    -- autocommands (event listeners)
    -- :help lua-guide-autocommands
    vim.api.nvim_create_autocmd('TextYankPost', {
        desc = 'Highlight when yanking text',
        group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
        callback = function() vim.hl.on_yank() end,
    })

end

-- ==================================================================================================== 
-- SECTION 3: Plugin Intro
-- vim.pack
-- ==================================================================================================== 
do
-- Notes about using vim.pack
-- more details, see https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
--
-- to update, run
-- :lua vim.pack.update()

-- function to run build commands for plugins after they are installed or updated
local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd}):wait()
    if result.code ~= 0 then
        local stderr = result.stderr or ''
        local stdout = result.stdout or ''
        local output = stderr ~= '' and stderr or stdout
        if output == '' then output = 'No output from build command.' end
        vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
end

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name = ev.data.spec.name
        local kind = ev.data.kind
        if kind ~= 'install' and kind ~= 'update' then return end

        if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
            run_build(name, { 'make' }, ev.data.path)
            return
        end

        if name == 'nvim-treesitter' then
            if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
            vim.cmd 'TSUpdate'
            return
        end
    end,
})


end

--- most plugins are hosted on github, this cuts down on repeated text
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ==================================================================================================== 
-- SECTION 4: UI / UX Plugins
-- ==================================================================================================== 
do
    -- most plugins need to call .setup(), simply installing them is not enough
    -- example: `guess-indent.nvim` is used to detect indentation from files

    -- first we install:
    vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
    -- then we call setup:
    require('guess-indent').setup {}


    -- autocomplete
    vim.pack.add {
        { src = gh 'ms-jpq/coq_nvim', version = 'coq' },
        { src = gh 'ms-jpq/coq.artifacts', version = 'artifacts' },
    }


    -- many plugins require more advanced config
    -- example: `gitsigns.nvim` to show pending git changes in buffers
    vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
    local gitsigns = require 'gitsigns'

end

-- ==================================================================================================== 
-- SECTION 5: LSP
-- ==================================================================================================== 
do
    -- language server
    vim.pack.add { gh 'neovim/nvim-lspconfig' }

    vim.lsp.enable('clangd')

    vim.lsp.config['lua_ls'] = {
          -- Command and arguments to start the server.
          cmd = { 'lua-language-server' },
          -- Filetypes to automatically attach to.
          filetypes = { 'lua' },
          -- Sets the "workspace" to the directory where any of these files is found.
          -- Files that share a root directory will reuse the LSP server connection.
          -- Nested lists indicate equal priority, see |vim.lsp.Config|.
          root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
          settings = {
              Lua = {
                  runtime = {
                      version = 'LuaJIT',
                  },
                  diagnostics = {
                      globals = {
                          'vim',
                          'require'
                      },
                 },
             },
        },
    }
    vim.lsp.enable('lua_ls')
end
