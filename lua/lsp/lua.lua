---@type vim.lsp.Config
local M = {}

M.name = "emmylua_ls"

M.filetypes = { "lua" }

M.cmd = { "emmylua_ls" }

-- M.root_dir = function(bufnr, on_dir)
-- 	local fname = vim.api.nvim_buf_get_name(bufnr)
-- 	-- Pour les fichiers de bibliothèque, utiliser la config nvim comme root
-- 	-- Cela rattache le buffer au serveur existant
-- 	if fname:match(vim.env.VIMRUNTIME) or fname:match("/lazy/") then
-- 		on_dir(vim.fn.stdpath("config"))
-- 		return
-- 	end
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
		},
		strict = {
			requirePath = true,
		},
		diagnostics = {
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

	runtime.version = "LuaJIT"
	runtime.requireLikeFunction = { "pRequire" }
	runtime.requirePattern = { "?.lua", "?/init.lua", "lua/?.lua", "lua/?/init.lua" }

	table.insert(lib, vim.fn.expand("$VIMRUNTIME/lua"))
	-- local folder = vim.fn.stdpath("data") .. "/lazy/"
	-- for name, _ in vim.fs.dir(folder) do
	-- 	table.insert(lib, vim.fs.joinpath(folder, name))
	-- end
end

local black_list = {
	["coder/claudecode.nvim"] = true,
}

local function add_plugins_to_lib(settings)
	local lib = settings.Lua.workspace.library
	local plugins = require("lazy").plugins()
	local lazy_conf = require("lazy-conf")
	local lazy_folder = vim.fn.stdpath("data") .. "/lazy/"
	local dev_folder = lazy_conf.dev.path

	table.insert(lib, vim.fs.joinpath(lazy_folder, "lazy.nvim"))

	---@param plugins_list (LazyPlugin|LazyPlugin[])[]
	local function add_lib(plugins_list)
		for _, plugin in ipairs(plugins_list) do
			if type(plugin[1]) == "table" then
				---@cast plugin LazyPluginSpec[]
				add_lib(plugin)
				goto continue
			end
			if plugin.enabled == false or black_list[plugin[1]] then
				goto continue
			end

			---@cast plugin LazyPluginSpec
			local name = plugin.name or plugin[1] and plugin[1]:match(".*/(.*)")
			if name then
				if plugin.dev then
					table.insert(lib, vim.fs.joinpath(dev_folder, name))
				else
					table.insert(lib, vim.fs.joinpath(lazy_folder, name))
				end
			elseif plugin.dir then
				table.insert(lib, plugin.dir)
			else
				vim.notify(
					"Impossible de déterminer le nom du plugin pour l'ajouter au LuaLS: " .. vim.inspect(plugin),
					vim.log.levels.WARN
				)
			end
			::continue::
		end
	end
	add_lib(plugins)
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
end

return M
