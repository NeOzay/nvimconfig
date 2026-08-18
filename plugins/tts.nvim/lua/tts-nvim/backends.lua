---@namespace tts-nvim

---Table d'enregistrement des backends. Un seul est fourni — `piper` — mais le point d'extension
---est conservé : un backend décrit comment traduire la configuration en requête pour le démon.

---@class backend
---@field name string
---@field build_request fun(cfg: config, text: string): table Requête `speak` envoyée au démon
---@field validate_config fun(cfg: config): boolean, string? Message d'erreur si invalide

---@class Backends
---@field backends table<string, backend>
local M = {}

---@type table<string, backend>
M.backends = {}

M.backends.piper = {
	name = "piper",

	---@param cfg config
	---@param text string
	---@return table
	build_request = function(cfg, text)
		return {
			op = "speak",
			text = text,
			voice = cfg.current_voice(),
			speed = cfg.speed,
			volume = cfg.volume,
		}
	end,

	---@param cfg config
	---@return boolean, string?
	validate_config = function(cfg)
		if type(cfg.speed) ~= "number" or cfg.speed <= 0 then
			return false, "speed doit être un nombre strictement positif"
		end
		if type(cfg.volume) ~= "number" or cfg.volume < 0 or cfg.volume > 1 then
			return false, "volume doit être un nombre entre 0.0 et 1.0"
		end
		return true
	end,
}

---@param name string
---@return backend?
---@nodiscard
function M.get_backend(name)
	return M.backends[name]
end

---@return string[]
---@nodiscard
function M.get_available_backends()
	local names = {} ---@type string[]
	for name in pairs(M.backends) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return M
