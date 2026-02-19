---@type LazyPluginSpec
return {
	"DrKJeff16/wezterm-types",
	lazy = true,
	version = false, -- Get the latest version
	cond = function()
		if vim.fs.find("wezterm.lua")[1] ~= nil then
			vim.notify(
				"WezTerm config detected, loading wezterm-types.nvim",
				vim.log.levels.INFO,
				{ title = "wezterm-types" }
			)
			vim.g.wezterm_types_loaded = true
			return true
		end
		return false
	end,
}
