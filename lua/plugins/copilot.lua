-- ===== ANCIEN CODE (commenté) =====
--[[
local function on_menu_opened()
	vim.b.copilot_suggestion_hidden = true
end

local function on_menu_closed()
	vim.b.copilot_suggestion_hidden = false
end

local function copilot_config()
	require("copilot").setup()
	local cmp = require("cmp")
	cmp.event:on("menu_opened", on_menu_opened)
	cmp.event:on("menu_closed", on_menu_closed)
end

local function copilot_cmp_config()
	require("copilot_cmp").setup()
end

---@type LazySpec[]
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = copilot_config,
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
		config = copilot_cmp_config,
	},
}
--]]

-- ===== NOUVEAU CODE (blink.cmp) =====
local function copilot_config()
	require("copilot").setup({
		suggestion = { enabled = false },
		panel = { enabled = false },
	})
end

---@type LazySpec[]
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = copilot_config,
	},
	{
		"giuxtaposition/blink-cmp-copilot",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
	},
}
