local function goto_next_reference()
	require("illuminate").goto_next_reference(false)
end

local function goto_prev_reference()
	require("illuminate").goto_prev_reference(false)
end

local function config(_, opts)
	require("illuminate").configure(opts)
end

---@type LazySpec
return {
	"RRethy/vim-illuminate",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		providers = {
			"lsp",
			"treesitter",
			"regex",
		},
		delay = 100,
		filetypes_allowlist = {
			"lua",
			"python",
			"javascript",
			"typescript",
			"html",
			"css",
			"json",
			"markdown",
			"yaml",
			"rust",
			"go",
			"java",
			"c",
			"cpp",
			"sh",
			"zsh",
			"vim",
			"ruby",
			"php",
			"swift",
			"kotlin",
		},
		modes_denylist = {},
		modes_allowlist = {},
		providers_regex_syntax_denylist = {},
		providers_regex_syntax_allowlist = {},
		under_cursor = true,
		large_file_cutoff = 5000,
		large_file_overrides = nil,
		min_count_to_highlight = 1,
		case_insensitive_regex = false,
	},
	config = config,
	keys = {
		{ "]]", goto_next_reference, desc = "Next Reference" },
		{ "[[", goto_prev_reference, desc = "Prev Reference" },
	},
}
