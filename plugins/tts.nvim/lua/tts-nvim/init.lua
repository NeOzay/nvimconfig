---@mod tts-nvim Lecture vocale d'une sélection, synthétisée par un démon Piper côté client
---@brief [[
---Neovim n'exécute aucune synthèse : il envoie du texte à un démon Piper qui écoute sur
---`127.0.0.1:<port>`. En local le démon est sur la même machine ; à travers SSH, un
---`RemoteForward` mène à celui du poste de travail. La configuration est donc identique des
---deux côtés — aucune détection de contexte.
---@brief ]]

---@namespace tts-nvim

---@class TtsNvim
local M = {}

local backends = require("tts-nvim.backends")
local client = require("tts-nvim.client")
local config = require("tts-nvim.config")
local util = require("tts-nvim.util")

---Envoie la sélection visuelle au démon pour lecture immédiate.
function M.tts()
	local backend = backends.get_backend(config.backend)
	if not backend then
		vim.notify(
			("tts-nvim : backend inconnu « %s » (disponibles : %s)"):format(
				config.backend,
				table.concat(backends.get_available_backends(), ", ")
			),
			vim.log.levels.ERROR
		)
		return
	end

	local valid, err = backend.validate_config(config)
	if not valid then
		vim.notify("tts-nvim : " .. (err or "configuration invalide"), vim.log.levels.ERROR)
		return
	end

	local text = util.getAndProcessText()
	if text == "" then
		return
	end

	client.request(backend.build_request(config, text))
end

---Demande au démon d'écrire la synthèse dans un fichier, sur la machine où il tourne.
function M.tts_to_file()
	local text = util.getAndProcessText()
	if text == "" then
		return
	end

	client.request({
		op = "save",
		text = text,
		voice = config.current_voice(),
		speed = config.speed,
	}, function(response)
		if response and response.path then
			vim.notify("tts-nvim : écrit dans " .. response.path, vim.log.levels.INFO)
		end
	end)
end

---Interrompt la lecture en cours.
function M.tts_stop()
	client.request({ op = "stop" })
end

---@param args { fargs: string[] }
function M.tts_set_language(args)
	local lang = args.fargs[1]
	config.language = lang

	local per_backend = config.languages_to_voice[config.backend]
	local voice = per_backend and per_backend[lang]
	if voice then
		vim.notify(("tts-nvim : langue %s (%s)"):format(lang, voice), vim.log.levels.INFO)
	else
		vim.notify(
			("tts-nvim : langue %s sans modèle cartographié, repli sur %s"):format(lang, config.piper_model),
			vim.log.levels.WARN
		)
	end
end

---@param args { fargs: string[] }
function M.tts_set_backend(args)
	local name = args.fargs[1]
	if not backends.get_backend(name) then
		vim.notify(
			("tts-nvim : backend inconnu « %s » (disponibles : %s)"):format(
				name,
				table.concat(backends.get_available_backends(), ", ")
			),
			vim.log.levels.ERROR
		)
		return
	end

	config.backend = name
	vim.notify("tts-nvim : backend " .. name, vim.log.levels.INFO)
end

---@return string[]
---@nodiscard
function M.get_available_backends()
	return backends.get_available_backends()
end

---@return string[]
---@nodiscard
function M.get_supported_languages()
	local languages = {} ---@type string[]
	local per_backend = config.languages_to_voice[config.backend]
	if per_backend then
		for lang in pairs(per_backend) do
			table.insert(languages, lang)
		end
	end
	table.sort(languages)
	return languages
end

---@param opts? Partial<config>
function M.setup(opts)
	config.setup(opts)
end

return M
