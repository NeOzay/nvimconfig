---@type LazyPluginSpec[]
local plugins = {}

local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"
local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)

local plugin, ok
for _, file in ipairs(files) do
	local name = vim.fn.fnamemodify(file, ":t:r")
	if name ~= "init" then
		plugin, ok = pRequire("plugins." .. name)
		if ok then
			table.insert(plugins, plugin)
		end
	end
end

return plugins
