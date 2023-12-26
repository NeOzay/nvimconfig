-- You dont need to set any of these options. These are the default ones. Only
-- the loading is important
local telescope = require('telescope')

local util = require("ozay.util")

telescope.setup {
    defaults = {
        mappings = {
            i = {
                ["<esc>"] = require("telescope.actions").close
            }
        }
    },
    extensions = {
        fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        },
        file_browser = {
            --theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
        },
    }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
local ok = pcall(telescope.load_extension, 'fzf')
if not ok then
    vim.notify("Error could no load Telescope extension 'fzf'")
end

require('telescope').load_extension('neoclip')
--require("telescope").load_extension "file_browser"

local builtin = require('telescope.builtin')
util.nnoremap('<leader>ff', builtin.find_files, "files")
util.nnoremap('<leader>fg', builtin.live_grep, "live grep")
util.nnoremap('<leader>fb', builtin.buffers, "buffers")
util.nnoremap('<leader>fh', builtin.help_tags, "help tag")
util.nnoremap('<leader>fj', builtin.highlights, "highlights")
util.nnoremap('<leader>fr', "<Cmd>Telescope neoclip<CR>", "neoclip")
