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
    -- using mini.statusline which shows mode
    vim.o.showmode = false

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

    -- allow folds based on lsp
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt.foldlevel = 99
    vim.opt.foldlevelstart = 99
    vim.opt.foldenable = true

end

-- ==================================================================================================== 
-- SECTION 2: keymaps and autocmds
-- ==================================================================================================== 

do
    vim.keymap.set('n', '<ESC>', '<cmd>nohlsearch<CR>')
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
    -- alt keymap for visual block when ctrl v is stolen
    vim.keymap.set('n', '<leader>v', '<C-v>')

    -- Toggling comments with ctrl / (like Jetbrains)
    vim.keymap.set('n', '<C-_>', 'gccj', { remap = true, desc = 'Toggle comment'})
    vim.keymap.set('x', '<C-_>', 'gc', { remap = true, desc = 'Toggle comment' })
    vim.keymap.set('i', '<C-_>', '<Esc>gccja', { remap = true, desc = 'Toggle comment' })

    -- most terminals send ctrl+/ as ctrl+_. If one ever fails, add these
    -- vim.keymap.set('n', '<C-/>', 'gccj', { remap = true, desc = 'Toggle comment' })
    -- vim.keymap.set('x', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment' })
    -- vim.keymap.set('i', '<C-/>', '<Esc>gcca', { remap = true, desc = 'Toggle comment' })  


    -- default terminal exit is ctrl + \, ctrl + n which is hard to remember
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

    -- diagnostic config
    vim.diagnostic.config {
        update_in_insert = false,
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

local function map_factory(desc_prefix, buffer)
    return function (keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = buffer, desc = desc_prefix .. desc })
    end
end

-- ==================================================================================================== 
-- SECTION 4: UI / UX Plugins
-- ==================================================================================================== 
do

    -- colorscheme
    vim.pack.add { { src = gh 'catppuccin/nvim', name = 'catppuccin' } }
    vim.cmd.colorscheme 'catppuccin-macchiato'


    -- most plugins need to call .setup(), simply installing them is not enough
    -- example: `guess-indent.nvim` is used to detect indentation from files
    -- first we install:
    vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
    -- then we call setup:
    require('guess-indent').setup {}

    -- many plugins require more advanced config
    -- example: `gitsigns.nvim` to show pending git changes in buffers
    vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
    local gitsigns = require 'gitsigns'
    gitsigns.setup {
        current_line_blame = true,
        signs = {
            add = { text = '+' }, ---@diagnostic disable-line: missing-fields
            change = { text = '~' }, ---@diagnostic disable-line: missing-fields
            delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
            topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
            changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields 
        },
        -- keymaps 
        on_attach = function(bufnr)
            -- create local function for maps
            local map = map_factory('Git: ', bufnr)

            -- Navigation
            -- neovim has a 'diff' mode natively, maintain those keybinds
            map(']c', function ()
                if vim.wo.diff then
                    vim.cmd.normal { ']c', bang = true }
                else
                    gitsigns.nav_hunk 'next'
                end
            end, 'Jump to next git [c]hange')

            vim.keymap.set('n', '[c', function()
                if vim.wo.diff then
                    vim.cmd.normal { '[c', bang = true }
                else
                    gitsigns.nav_hunk 'prev'
                end
            end, { desc = 'Jump to previous git [c]hange', buf = bufnr })

            -- Visual Mode Actions
            -- TODO: add more git keymaps as required, this is all I use currently
            vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against last commit', buf = bufnr })
            vim.keymap.set('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line', buf = bufnr })
            vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line', buf = bufnr })

        end,
    }

    -- helpful for remembering keybinds
    vim.pack.add { gh 'folke/which-key.nvim' }
    require('which-key').setup {
        delay = 150,
        icons = { mappings = vim.g.have_nerd_font },
        spec = {
            { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
            { '<leader>t', group = '[T]oggle', mode = { 'n', 'v' } },
            { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
            { 'gr', group = 'LSP Actions', mode = { 'n' } },
        }
   }

   -- Highlight todo, notes, etc
   vim.pack.add { gh 'folke/todo-comments.nvim' }
   require( 'todo-comments').setup { signs = true }

   -- [[ mini.nvim ]]
   -- various independent plugins
   vim.pack.add { gh 'nvim-mini/mini.nvim' }

   -- if a nerd font is available, load it for pretty icons
   if vim.g.have_nerd_font then
       require('mini.icons').setup()
       -- backwards compatibility
       MiniIcons.mock_nvim_web_devicons()
   end

   -- better around/inside
   --
   -- Examples:
   --  - va) [V]isually select [A]round [)]paren
   --  - yiiq [Y]ank [I]nside [I]+1 [Q]uote
   --  - ciq [C]hange [I]nside [Q]uote
   require('mini.ai').setup {
       mappings = {
           around_next = 'aa',
           inside_next = 'ii',
       },
       n_lines = 500,
   }

   local statusline = require 'mini.statusline'
   statusline.setup { use_icons = vim.g.have_nerd_font }

   ---@diagnostic disable-next-line: duplicate-set-field
   statusline.section_location = function() return '%2l:%-2v' end
end


-- ==================================================================================================== 
-- SECTION 5: SEARCH & NAVIGATION
-- ==================================================================================================== 
do
    -- [[ Fuzzy Finder (files, lsp, etc) ]]
    --
    -- Telescope is the standard fuzzy finder for everything
    --
    -- Start with :Telescope help_tags
    --
    -- The most important keymaps with Telescope are:
    --  - Insert mode: <c-/>
    --  Normal mode: ?
    --
    --  This opens a window that shows all keymaps for the current telescope picker

    ---@type (string | vim.pack.Spec)[]
    local telescope_plugins = {
        gh 'nvim-lua/plenary.nvim',
        gh 'nvim-telescope/telescope.nvim',
        gh 'nvim-telescope/telescope-ui-select.nvim',
    }
    -- add telescope fzf native if it can compile
    if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

    vim.pack.add(telescope_plugins)

    -- See `:help telescope` and `:help telescope_setup()`
    require('telescope').setup {
        extensions = {
            ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
    }

    -- Enable telescope extensions
    -- pcall: calls function in protected mode, meaning any errors
    -- are not propagated; instead it catches the error and returns
    -- a status code.
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    -- "Builtins is a collection of community maintained pickers"
    -- "picker": the UI/main function that actually determines what you're searching: listing files, or git changed files, or text within files, etc.
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    -- select picker
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
    vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc ='[ ] Find existing buffers' })
    vim.keymap.set('n', '<leader>sb', builtin.current_buffer_fuzzy_find, { desc = '[S]earch current [B]uffer' })

    -- telescope and LSP combination config, pickers for LSP actions
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', {clear = true }),
        callback = function(event)
            local buf = event.buf

            vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

            vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementations' })

            vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
        end,
    })

    vim.keymap.set('n', '<leader>/', function()
        -- pass in additional config to change theme, layout, etc
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
        })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- search neovim config
    vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })
end

-- ==================================================================================================== 
-- SECTION 6: LSP
-- LSP keymaps, server config, mason
-- ==================================================================================================== 

do
    -- an LSP is a process that runs outside of neovim and parses files for their language,
    -- and communiates with the client -- neovim. Allows things like goto definition, find references
    -- auto complete, etc

    -- These language servers need to be installed separately, which is where `mason` helps

    -- notifications, useful for LSP status
    vim.pack.add { gh 'j-hui/fidget.nvim' }
    require('fidget').setup {}


    -- this function runs when the LSP attaches to a buffer, to set up LSP behavior
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)

            -- helper function for setting keybinds
            -- TODO: pull this up, use for all keybinds?
            local map = function(keys, func, desc, mode)
                mode = mode or 'n'
                vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
            end

            -- Rename variable under cursor
            map( 'grn', vim.lsp.buf.rename, '[R]e[n]ame')
            -- TODO: add more LSP keybinds

            map('gra', vim.lsp.buf.code_action, '[G]oto Code [Action]', {'n', 'x'})


            -- note this is goto Declaration, for ex. the header
            -- less useful than definition, so it uses uppercase D
            map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')


            -- highlight references under cursor when the cursor sits for a bit
            -- See `:help CursorHold`
            -- When the cursor is moved, the highlights are cleared (second autocmd)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client:supports_method('textDocument/documentHighlight', event.buf) then
                local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
                vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    buffer = event.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.document_highlight,
                })

                vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                    buffer = event.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.clear_references,
                })

                vim.api.nvim_create_autocmd('LspDetach', {
                    group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                    end,
                })
            end


            -- keymap to toggle inlay hints
            if client and client:supports_method('textDocument/inlayHint', event.buf) then
                vim.lsp.inlay_hint.enable(true)
                map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
            end
        end,
    })


    -- Enabling language servers
    -- see `:help lsp-config` for info
    ---@type table<string, vim.lsp.Config>
    local servers = {
        clangd = {},
        csharp_ls = {},
        tsc = {},
        rust_analyzer = {}, -- TODO: check out rustaceanvim for alternative full plugin
        stylua = {}, -- used to format lua code
        -- special lua config as specified in the nvim help docs
        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end

            local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
            ---@diagnostic disable-next-line: assign-type-mismatch
            client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                library = vim.api.nvim_get_runtime_file('', true),
              },
            })
          end,
          ---@type lspconfig.settings.lua_ls
          settings = {
            Lua = {
              format = { enable = false }, -- Disable formatting (formatting is done by stylua)
            },
          },
        },
      }

      vim.pack.add {
          gh 'neovim/nvim-lspconfig',
          gh 'mason-org/mason.nvim',
          gh 'mason-org/mason-lspconfig.nvim',
          gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
      }

      -- Auto install LSPs to stdpath for neovim
      require('mason').setup {}

      -- Translate between nvim-lspconfig server names and mason.nvim package names (lua_ls <-> lua-language-server)
      require('mason-lspconfig').setup {
          automatic_enable = true -- auto enable servers that are installed manually via :MasonInstall
      }

      -- Ensure the servers are installed
      -- To check the current status or manually install more, we can run
      -- :Mason
      --
      -- and press g? in the menu to get help
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
          -- can add other tools here for Mason to install
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
          vim.lsp.config(name, server)
          vim.lsp.enable(name)
      end
end


-- ==================================================================================================== 
-- SECTION 7: FORMATTING
-- ==================================================================================================== 
do
    vim.pack.add { gh 'stevearc/conform.nvim' }
    require('conform').setup {
        notify_on_error = false,
        format_on_ave = function(bufnr)
            local enabled_filetypes = {
                lua = true,
            }
            if enabled_filetypes[vim.bo[bufnr].filetype] then
                return { timeout_ms = 500 }
            else
                return nil
            end
        end,
        default_format_opts = {
            lsp_format = 'fallback', -- use external formatters if configured, otherwise lsp.
        },
        formatters_by_ft = {
            rust = { 'rustfmt' }
        },
    }

    vim.keymap.set({'n', 'v'}, '<leader>f', function()
        require('conform').format { async = true }
    end,
    { desc = '[F]ormat buffer' })
end


-- ==================================================================================================== 
-- SECTION 8: AUTOCOMPLETE
-- ==================================================================================================== 
do
    vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
    require('blink.cmp').setup {
        keymap = {
            -- 'default' keybind:
            -- <c-y> to accept ([y]es) the completion.
            --
            -- 'super-tab' for tab to accept
            -- 'enter' for enter to accept
            -- 'none' for no mappings
            --
            -- read :help ins-completion' for why 'default' is recommended
            -- All presets have the following maps:
            -- <tab>/<s-tab>: move to right/left of snippet expansion
            -- <c-space>: Open menu or docs
            -- <c-n>/<c-p> or <up><down>: select next/previous item
            -- <c-e>: Hide menu
            -- <c-k>: Toggle signature help
            preset = 'default',
        },

        appearance = {
            nerd_font_variant = 'mono',
        },

        completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 500 },
        },

        sources = {
            default = { 'lsp', 'path' },
        },

        fuzzy = { implementation = 'prefer_rust_with_warning' },
        signature = { enabled = true },
    }
end


-- ==================================================================================================== 
-- SECTION 9: Tree
-- ==================================================================================================== 

do
    vim.pack.add {
        { src = gh 'nvim-neo-tree/neo-tree.nvim', version =vim.version.range '*' },
        gh 'nvim-lua/plenary.nvim',
        gh 'MunifTanjim/nui.nvim'
    }

    vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'Neotree reveal', silent = true })

    require ('neo-tree').setup {
        filesystem = {
            window = {
                mappings = {
                    ['\\'] = 'close_window'
                },
            },
        },
    }
end


-- ==================================================================================================== 
-- SECTION 10: Additional Plugins
-- ==================================================================================================== 
do
    -- my plugins, not part of the initial set provided by kickstart.
    vim.pack.add {
        gh 'm4xshen/hardtime.nvim'
    }
    require('hardtime').setup {
        -- layered keyboard means arrow keys are where hjkl would be
        disabled_keys = {
            ['<Up>' ] = false,
            ['<Down>'] = false,
            ['<Left>'] = false,
            ['<Right>'] = false,
        },
        restriction_mode = "block",
    }

    vim.pack.add {
        gh 'folke/flash.nvim'
    }
    require('flash').setup {
        modes = {
            search = {
                enabled = true
            },
        },
    }

    vim.keymap.set( { 'n', 'x', 'o'}, 's',function() require('flash').jump() end, {desc = 'Flash' })
    -- unsure of what this is supposed to do
    -- vim.keymap.set({'n', 'x', 'o'}, 'S', function() require('flash').treesitter() end, {desc = 'flash treesitter'})
    vim.keymap.set( { 'o' }, 'r', function() require('flash').remote() end, { remap = true, desc = 'Remote Flash' })
    vim.keymap.set('c', '<c-s>', function() require('flash').toggle() end, { desc = 'toggle flash search' })
end
