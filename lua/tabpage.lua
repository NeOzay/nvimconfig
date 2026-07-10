--- Gestion des noms de tabpages (aucun nom natif dans Neovim).
--- Le nom custom est stocké dans la variable de tabpage `tabname`.
local M = {}

---@param tabnr? integer
---@return integer
local function resolve(tabnr)
	return tabnr or vim.api.nvim_get_current_tabpage()
end

--- Nom d'un tab créé par CodeDiff (session active pour ce tabnr), basé sur le
--- fichier actuellement affiché dans le diff. `nil` si CodeDiff n'est pas
--- chargé ou si ce tab n'a pas de session CodeDiff.
---@param tabnr integer
---@return string?
local function codediff_name(tabnr)
	local ok, accessors = pcall(require, "codediff.ui.lifecycle.accessors")
	if not ok then
		return nil
	end
	local original_path, modified_path = accessors.get_paths(tabnr)
	local path = modified_path or original_path
	if not path or path == "" then
		return nil
	end
	return "CodeDiff"
end

--- Nom par défaut : session CodeDiff active sur ce tab, sinon basename du cwd
--- local au tab s'il diffère du cwd global, sinon numéro du tab.
---@param tabnr integer
---@return string
local function default_name(tabnr)
	local diff_name = codediff_name(tabnr)
	if diff_name then
		return diff_name
	end

	local tabpage_nr = vim.api.nvim_tabpage_get_number(tabnr)
	local tab_cwd = vim.fn.getcwd(-1, tabpage_nr)
	local global_cwd = vim.fn.getcwd(-1, -1)
	if tab_cwd ~= global_cwd then
		return vim.fs.basename(tab_cwd)
	end

	return tostring(tabpage_nr)
end

---@param tabnr? integer
---@return string
function M.get_name(tabnr)
	tabnr = resolve(tabnr)
	local ok, name = pcall(vim.api.nvim_tabpage_get_var, tabnr, "tabname")
	if ok and name and name ~= "" then
		return name
	end
	return default_name(tabnr)
end

---@param name string
---@param tabnr? integer
function M.set_name(name, tabnr)
	vim.api.nvim_tabpage_set_var(resolve(tabnr), "tabname", name)
end

--- Demande interactivement un nouveau nom et l'applique.
---@param tabnr? integer
---@param on_done? fun() rappelé après application du nouveau nom
function M.rename(tabnr, on_done)
	tabnr = resolve(tabnr)
	vim.ui.input({ prompt = "Nom du tab: ", default = M.get_name(tabnr) }, function(input)
		if input and input ~= "" then
			M.set_name(input, tabnr)
			if on_done then
				on_done()
			end
		end
	end)
end

return M
