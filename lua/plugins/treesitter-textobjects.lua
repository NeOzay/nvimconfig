local function select_textobject(query)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
	end
end

local function init()
	vim.g.no_plugin_maps = true
end

---@type LazySpec
return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = "BufEnter",
	branch = "main",
	init = init,
	opts = {
		select = {
			lookahead = true,
			selection_modes = {
				["@parameter.outer"] = "v",
				["@function.outer"] = "v",
			},
			include_surrounding_whitespace = false,
		},
	},
	keys = {
		{ "af", select_textobject("@function.outer"), mode = { "o", "x" }, desc = "Select around function" },
		{ "if", select_textobject("@function.inner"), mode = { "o", "x" }, desc = "inner function" },

		{ "aa", select_textobject("@call.outer"), mode = { "o", "x" }, desc = "Select around call" },
		{ "ia", select_textobject("@call.inner"), mode = { "o", "x" }, desc = "inner call" },

		{ "aC", select_textobject("@class.outer"), mode = { "o", "x" }, desc = "Select around class" },
		{ "iC", select_textobject("@class.inner"), mode = { "o", "x" }, desc = "inner class" },

		{ "ap", select_textobject("@parameter.outer"), mode = { "o", "x" }, desc = "Select around parameter" },
		{ "ip", select_textobject("@parameter.inner"), mode = { "o", "x" }, desc = "inner parameter" },

		{ "al", select_textobject("@loop.outer"), mode = { "o", "x" }, desc = "Select around loop" },
		{ "il", select_textobject("@loop.inner"), mode = { "o", "x" }, desc = "inner loop" },

		{ "ai", select_textobject("@conditional.outer"), mode = { "o", "x" }, desc = "Select around conditional" },
		{ "ii", select_textobject("@conditional.inner"), mode = { "o", "x" }, desc = "inner conditional" },

		{ "ac", select_textobject("@condition.outer"), mode = { "o", "x" }, desc = "Select around condition" },
		{ "ic", select_textobject("@condition.inner"), mode = { "o", "x" }, desc = "inner condition" },
	},
}
