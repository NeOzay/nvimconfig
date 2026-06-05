local black_list = {}

local type_skip = {
	lua = true,
	plugin = true,
	doc = true,
	tests = true,
	test = true,
	spec = true,
	bench = true,
	[".git"] = true,
	[".github"] = true,
}

---@param root_dir string
---@return boolean
local function is_nvim_env(root_dir)
	if vim.uv.fs_stat(root_dir .. "/init.lua") or vim.uv.fs_stat(root_dir .. "/init.vim") then
		return true
	end
	local lua_dir = vim.uv.fs_stat(root_dir .. "/lua")
	local plugin_dir = vim.uv.fs_stat(root_dir .. "/plugin")
	return (lua_dir and lua_dir.type == "directory") or (plugin_dir and plugin_dir.type == "directory") or false
end

---@param subdir string
---@return boolean
local function has_meta_file(subdir)
	local handle = vim.uv.fs_scandir(subdir)
	if not handle then
		return false
	end
	while true do
		local fname, ftype = vim.uv.fs_scandir_next(handle)
		if not fname then
			return false
		end
		if ftype ~= "file" or not fname:match("%.lua$") then
			goto next
		end
		local f = io.open(vim.fs.joinpath(subdir, fname))
		if not f then
			goto next
		end
		local first = f:read("*l")
		f:close()
		if first and first:match("^%-%-%-%s*@meta") then
			return true
		end
		::next::
	end
end

---@param lib string[]
---@param dir string
local function add_type_dirs(lib, dir)
	local handle = vim.uv.fs_scandir(dir)
	if not handle then
		return
	end
	while true do
		local name, kind = vim.uv.fs_scandir_next(handle)
		if not name then
			return
		end
		if not (kind == "directory") or type_skip[name] then
			goto next
		end
		local subdir = vim.fs.joinpath(dir, name)
		if has_meta_file(subdir) then
			table.insert(lib, subdir)
		end
		::next::
	end
end

---@param settings table
local function add_nvim_libs(settings)
	local lib = settings.Lua.workspace.library
	local runtime = settings.Lua.runtime
	local workspace = settings.Lua.workspace
	local diagnostics = settings.Lua.diagnostics

	workspace.ignoreGlobs = { "**/minit.lua", "**/busted.lua", "**/tests/**", "**/spec/**", "**/test/**" }
	workspace.ignoreDir = { "deps" }
	runtime.version = "LuaJIT"
	runtime.requireLikeFunction = { "pRequire" }
	runtime.requirePattern = { "?.lua", "?/init.lua", "lua/?.lua", "lua/?/init.lua" }
	diagnostics.disable = { "unnecessary-if" }
	table.insert(lib, vim.fn.expand("$VIMRUNTIME/lua"))
end

---@param settings table
---@param whitelist? string[]
local function add_plugins_to_lib(settings, whitelist)
	local lib = settings.Lua.workspace.library
	local lazy_folder = vim.fn.stdpath("data") .. "/lazy/"

	table.insert(lib, vim.fs.joinpath(lazy_folder, "lazy.nvim"))

	for _, plugin in ipairs(require("lazy").plugins()) do
		local name = plugin.name
		if plugin.enabled == false or black_list[name] then
			goto continue
		end
		if whitelist and not vim.list_contains(whitelist, name) then
			goto continue
		end
		local dir = vim.fn.resolve(plugin.dir)
		local lua_path = vim.fs.joinpath(dir, "lua")
		if vim.uv.fs_stat(lua_path) then
			table.insert(lib, lua_path)
		end
		add_type_dirs(lib, dir)
		::continue::
	end
end

---@param params lsp.InitializeParams
---@param config vim.lsp.ClientConfig
local function before_init(params, config)
	local root_dir = type(params.rootUri) == "string" and vim.uri_to_fname(params.rootUri) or nil

	if root_dir and is_nvim_env(root_dir) then
		add_nvim_libs(config.settings)
		add_plugins_to_lib(config.settings)
	end

	if vim.g.wezterm_types_loaded then
		add_plugins_to_lib(config.settings, { "wezterm-types" })
		---@diagnostic disable-next-line
		config.settings.Lua.workspace.ignoreGlobs = { "wezterm.lua" }
	end

	if params.workspaceFolders then
		table.insert(params.workspaceFolders, {
			uri = vim.uri_from_fname(vim.fn.stdpath("data") .. "/scratch"),
			name = "scratch",
		})
	end
end

---@type vim.lsp.Config
return {
	filetypes = { "lua" },

	settings = {
		Lua = {
			runtime = {},
			workspace = {
				library = {},
				checkThirdParty = false,
				ignoreDir = {},
				ignoreGlobs = {},
			},
			strict = { requirePath = true },
			diagnostics = { enable = true, disable = {} },
			hint = { enable = true },
		},
	},

	before_init = before_init,
}
