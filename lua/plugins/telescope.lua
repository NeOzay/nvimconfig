local utils = require("utils")

--- Open a telescope picker with prompt memory.
--- Restores the last prompt text and selects it so typing replaces it.
---@param name string builtin picker name
---@param extra_opts? table extra picker options
local function pick(name, extra_opts)
	local last_prompt = ""
	return function()
		local opts = vim.tbl_extend("force", extra_opts or {}, {
			default_text = last_prompt,
			attach_mappings = function(prompt_bufnr)
				vim.api.nvim_create_autocmd("BufLeave", {
					buffer = prompt_bufnr,
					once = true,
					callback = function()
						local lines = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)
						local line = lines[1] or ""
						local prefix = require("telescope.config").values.prompt_prefix or "> "
						if vim.startswith(line, prefix) then
							line = line:sub(#prefix + 1)
						end
						last_prompt = vim.trim(line)
					end,
				})
				local once = false
				vim.keymap.set("i", "<BS>", function()
					if once then
						return "<BS>"
					end
					once = true
					local line = vim.api.nvim_get_current_line()
					local prefix = require("telescope.config").values.prompt_prefix or "> "
					prefix = utils.escape_pattern(prefix)
					if line:gsub(prefix, "") == last_prompt then
						return ("<BS>"):rep(#last_prompt)
					end
					return "<BS>"
				end, { buffer = prompt_bufnr, expr = true })
				return true
			end,
		})

		require("telescope.builtin")[name](opts)
	end
end

local function opts(_, _opts)
	_opts.extensions = {
		aerial = {
			col1_width = 4,
			col2_width = 30,
			format_symbol = function(symbol_path, filetype)
				if filetype == "json" or filetype == "yaml" then
					return table.concat(symbol_path, ".")
				else
					return symbol_path[#symbol_path]
				end
			end,
			show_columns = "both",
		},
	}

	local open_with_trouble = require("trouble.sources.telescope").open
	_opts = vim.tbl_deep_extend("force", _opts, {
		defaults = {
			mappings = {
				i = { ["<c-q>"] = open_with_trouble },
				n = { ["<c-q>"] = open_with_trouble },
			},
		},
	})

	return _opts
end

---@type LazyPluginSpec
return {
	"nvim-telescope/telescope.nvim",
	-- enabled = false,
	opts = opts,
	-- keys = {
	-- 	{ "<leader>fw", pick("live_grep"), desc = "telescope live grep" },
	-- 	{ "<leader>fb", pick("buffers"), desc = "telescope find buffers" },
	-- 	{ "<leader>fh", pick("help_tags"), desc = "telescope help page" },
	-- 	{ "<leader>ma", pick("marks"), desc = "telescope find marks" },
	-- 	{ "<leader>fo", pick("oldfiles"), desc = "telescope find oldfiles" },
	-- 	{ "<leader>fz", pick("current_buffer_fuzzy_find"), desc = "telescope find in current buffer" },
	-- 	{ "<leader>cm", pick("git_commits"), desc = "telescope git commits" },
	-- 	{ "<leader>gt", pick("git_status"), desc = "telescope git status" },
	-- 	{ "<leader>pt", "<cmd>Telescope terms<CR>", desc = "telescope pick hidden term" },
	-- 	{ "<leader>ff", pick("find_files"), desc = "telescope find files" },
	-- 	{
	-- 		"<leader>fa",
	-- 		pick("find_files", { follow = true, no_ignore = true, hidden = true }),
	-- 		desc = "telescope find all files",
	-- 	},
	-- 	{ "<F3>", pick("find_files"), desc = "telescope find files" },
	-- 	{
	-- 		"<leader>fj",
	-- 		function()
	-- 			require("pickers").jumplist()
	-- 		end,
	-- 		desc = "Telescope jumplist",
	-- 	},
	-- },
	config = function(_, _opts)
		local telescope = require("telescope")
		-- vim.schedule(function()
		-- 	vim.print(_opts)
		-- end)
		telescope.setup(_opts)
		telescope.load_extension("aerial")
	end,
}
