---@namespace tts-nvim

---@class config
---@field host string Toujours la boucle locale : en SSH, un `RemoteForward` y mène
---@field port integer Port du démon
---@field timeout_ms integer Délai au-delà duquel la requête est abandonnée
---@field language string Langue courante, clé de `languages_to_voice`
---@field voice? string Modèle imposé ; nil = déduit de `language`
---@field speed number 1.0 = vitesse nominale, >1 accélère
---@field volume number Volume appliqué par le démon à la lecture, 0.0 à 1.0
---@field remove_syntax boolean Nettoyer la syntaxe du filetype avant lecture
---@field syntax_removal_method "simple"|"pandoc"
---@field backend string Nom du backend enregistré dans `tts-nvim.backends`
---@field languages_to_voice table<string, table<string, string>> backend -> langue -> modèle
---@field piper_model string Modèle de repli quand la langue n'est pas cartographiée

---@class Config: config
local M = {}

---@type config
local defaults = {
	host = "127.0.0.1",
	port = 7788,
	timeout_ms = 2000,

	language = "fr",
	speed = 1.0,
	volume = 1.0,
	remove_syntax = false,
	syntax_removal_method = "pandoc",
	backend = "piper",

	languages_to_voice = {
		piper = {
			["en"] = "en_US-lessac-medium",
			["fr"] = "fr_FR-siwis-medium",
			["de"] = "de_DE-thorsten-medium",
			["es"] = "es_ES-sharvard-medium",
			["it"] = "it_IT-riccardo-x_low",
			["pt"] = "pt_BR-faber-medium",
			["ja"] = "ja_JP-haruka-medium",
			["zh"] = "zh_CN-huayan-medium",
		},
	},

	piper_model = "fr_FR-siwis-medium",
}

---Fusionne les options utilisateur dans le module.
---`vim.tbl_deep_extend` renvoie une nouvelle table sans muter la première : on recopie donc le
---résultat champ par champ, sinon `setup()` n'aurait aucun effet observable.
---@param opts? Partial<config>
function M.setup(opts)
	for key, value in pairs(vim.tbl_deep_extend("force", defaults, opts or {})) do
		M[key] = value
	end
end

---Modèle Piper effectivement utilisé : le choix explicite s'il y en a un, sinon celui de la
---langue courante, sinon le repli.
---@return string
---@nodiscard
function M.current_voice()
	if M.voice then
		return M.voice
	end
	local per_backend = M.languages_to_voice[M.backend]
	return (per_backend and per_backend[M.language]) or M.piper_model
end

setmetatable(M, {
	__index = function(_, key)
		return defaults[key]
	end,
})

return M
