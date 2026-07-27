---@namespace hover-translator

---@class config
---@field translator string
---@field target_lang string
---@field border string
---@field cache config.cache

---@class config.cache
---@field enabled boolean
---@field ttl number TTL in seconds

---@class Config:config
local M = {}

---@type config
local defaults = {
	translator = "google",
	target_lang = "fr",
	border = "rounded",
	cache = {
		enabled = true,
		ttl = 3600, -- 1 hour in seconds
	},
}

---Setup configuration with user options
---@param opts? Partial<config>
function M.setup(opts)
	---@diagnostic disable-next-line
	vim.tbl_deep_extend("force", M, opts or {})
end

setmetatable(M, {
	__index = function(_, key)
		return defaults[key]
	end,
})

return M
