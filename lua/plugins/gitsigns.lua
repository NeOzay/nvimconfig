---@type LazySpec
return {
	"lewis6991/gitsigns.nvim",
	event = "User FilePost",
	opts = {
		preview_config = {
			style = "minimal",
			border = "rounded",
			relative = "cursor",
			row = 0,
			col = 1,
		},
	},
}
