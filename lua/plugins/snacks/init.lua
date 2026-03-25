---@diagnostic disable: missing-fields

---@class SnacksSubmodule
---@field opts snacks.Config
---@field keys LazyKeysSpec[]

---@type SnacksSubmodule[]
local modules = {
	require("plugins.snacks.notifier"),
	require("plugins.snacks.terminal"),
	require("plugins.snacks.scratch"),
	require("plugins.snacks.picker"),
	require("plugins.snacks.explorer"),
}

---@type snacks.Config
local merged_opts = {
	input = { enabled = true },
	words = { enabled = true },
}
---@type LazyKeysSpec[]
local merged_keys = {}

for _, mod in ipairs(modules) do
	merged_opts = vim.tbl_deep_extend("force", merged_opts, mod.opts or {})
	vim.list_extend(merged_keys, mod.keys or {})
end

---@type LazyPluginSpec
return {
	"folke/snacks.nvim",
	lazy = false,
	-- enabled = false,
	priority = 1000,
	dev = true,
	opts = merged_opts,
	config = true,
	keys = merged_keys,
}
