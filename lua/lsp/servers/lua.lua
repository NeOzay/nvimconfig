local settings = require("mason.settings")
---@type vim.lsp.Config
local M = {}

M.name = "emmylua_ls"

M.filetypes = { "lua" }

M.cmd = { "emmylua_ls", "--log-level", "debug" }

-- M.root_dir = function(bufnr, on_dir)
-- 	local fname = vim.api.nvim_buf_get_name(bufnr)
-- 	-- Pour les fichiers de bibliothèque, utiliser la config nvim comme root
-- 	-- Cela rattache le buffer au serveur existant
-- 	if fname:find(vim.env.VIMRUNTIME) or fname:find("/lazy/") or fname:find("/nvim%-plugins/") then
-- 		on_dir(vim.fn.stdpath("config"))
-- 		return
-- 	end
-- 	vim.print(fname)
-- 	-- Comportement normal pour les autres fichiers
-- 	local root = vim.fs.root(bufnr, { ".git", "init.lua", ".luarc.json" })
-- 	if root then
-- 		on_dir(root)
-- 		return
-- 	end
-- 	on_dir(vim.fn.getcwd())
-- end

M.settings = {
	Lua = {
		runtime = {},
		workspace = {
			library = {},
			checkThirdParty = false,
			ignoreDir = {},
			ignoreGlobs = {},
		},
		strict = {
			requirePath = true,
		},
		diagnostics = {
			enable = true,
		},
		hint = {
			enable = true,
		},
	},
}

---@return boolean
local function is_nvim_env(root_dir)
	-- Config Neovim: contient init.lua ou init.vim
	if vim.uv.fs_stat(root_dir .. "/init.lua") or vim.uv.fs_stat(root_dir .. "/init.vim") then
		return true
	end
	-- Plugin Neovim: contient un dossier lua/ ou plugin/
	local lua_dir = vim.uv.fs_stat(root_dir .. "/lua")
	local plugin_dir = vim.uv.fs_stat(root_dir .. "/plugin")
	if (lua_dir and lua_dir.type == "directory") or (plugin_dir and plugin_dir.type == "directory") then
		return true
	end
	return false
end

--- Ajoute les librairies Neovim au workspace
---@param settings table?
local function add_nvim_libs(settings)
	if not settings then
		return
	end
	local lib = settings.Lua.workspace.library
	local runtime = settings.Lua.runtime
	local workspace = settings.Lua.workspace

	runtime.version = "LuaJIT"
	runtime.requireLikeFunction = { "pRequire" }
	runtime.requirePattern = { "?.lua", "?/init.lua", "lua/?.lua", "lua/?/init.lua" }
	-- workspace.ignoreDir = { "spec" }

	table.insert(lib, vim.fn.expand("$VIMRUNTIME/lua"))
end

local black_list = {
	["claudecode.nvim"] = true,
	["promise-async"] = true,
}

local function add_plugins_to_lib(settings, whitelist)
	local lib = settings.Lua.workspace.library
	local plugins = require("lazy").plugins()

	local lazy_folder = vim.fn.stdpath("data") .. "/lazy/"

	local function is_whitelisted(plugin_name)
		if not whitelist then
			return true
		end
		for _, name in ipairs(whitelist) do
			if name == plugin_name then
				return true
			end
		end
		return false
	end

	table.insert(lib, vim.fs.joinpath(lazy_folder, "lazy.nvim"))

	for _, plugin in ipairs(plugins) do
		local name = plugin.name
		if plugin.enabled == false or black_list[name] or not is_whitelisted(name) then
			goto continue
		end
		table.insert(lib, vim.fn.resolve(plugin.dir))

		::continue::
	end
end

function M.before_init(params, config)
	local root_dir
	if type(params.rootUri) == "string" then
		root_dir = vim.uri_to_fname(params.rootUri)
	end
	if root_dir and is_nvim_env(root_dir) then
		add_nvim_libs(config.settings)
		add_plugins_to_lib(config.settings)
	end
	if vim.g.wezterm_types_loaded then
		add_plugins_to_lib(config.settings, { "wezterm-types" })
		---@diagnostic disable-next-line
		config.settings.Lua.workspace.ignoreGlobs = { "wezterm.lua" }
	end
end

return M
