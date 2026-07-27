---@namespace docstring-highlight

---@class ConfigModule:Config
local M = {}

---@alias hl_enum
---| "DocstringSection"
---| "DocstringUnknownSection"
---| "DocstringHeading"
---| "DocstringParam"
---| "DocstringType"
---| "DocstringTypeMatch"
---| "DocstringTypeMismatch"
---| "DocstringInlineCode"
---| "DocstringCodeBlock"

---@class config
---@field hl? table<hl_enum, vim.api.keyset.highlight> Custom highlight groups
---@field debounce? number Debounce delay in ms (default 150)
---@field priority? number Extmark priority (default 200)
---@field codeblock_blend? number 0-100 blend for code block highlights (default 0)
---@field bg? string Background color for docstring highlights (optional)
---@field sections? string[] Whitelist of recognized section keywords (default: Google style)

---@type string[]
local default_sections = {
	"Args",
	"Arguments",
	"Attributes",
	"Deprecated",
	"Example",
	"Examples",
	"Keyword Args",
	"Keyword Arguments",
	"Methods",
	"Note",
	"Notes",
	"Other Parameters",
	"Parameters",
	"Params",
	"Raise",
	"Raises",
	"Reference",
	"References",
	"Return",
	"Returns",
	"See Also",
	"Todo",
	"Warn",
	"Warns",
	"Warning",
	"Warnings",
	"Yield",
	"Yields",
}

---@type table<hl_enum, vim.api.keyset.highlight>
local default_hl = {
	DocstringSection = { default = true, link = "@markup.heading" },
	DocstringUnknownSection = { default = true, link = "DiagnosticWarn" },
	DocstringHeading = { default = true, link = "@markup.strong" },
	DocstringParam = { default = true, link = "@variable.parameter" },
	DocstringType = { default = true, link = "@type" },
	DocstringTypeMatch = { default = true, link = "@type" },
	DocstringTypeMismatch = { default = true, link = "DiagnosticWarn" },
	DocstringInlineCode = { default = true, link = "@markup.raw" },
	DocstringCodeBlock = { default = true, link = "@comment" },
	-- DocstringBackground = { default = true },
}

---@class Config:config
---@field hl table<hl_enum, vim.api.keyset.highlight>
---@field sections string[]
local defaut_config = {
	hl = {},
	debounce = 150,
	priority = 200,
	codeblock_blend = 0,
	bg = nil, ---@type string?
	sections = default_sections,
}

function M.setup(opts)
	local config = vim.tbl_deep_extend("force", vim.deepcopy(defaut_config), opts or {})
	for group, default_def in pairs(default_hl) do
		config.hl[group] = config.hl[group] or default_def
	end
	M.config = config
	M.__index = M.config
	return config
end

M.setup()

setmetatable(M, M)

return M
