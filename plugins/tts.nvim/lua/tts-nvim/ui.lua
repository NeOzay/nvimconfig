---@namespace tts-nvim

---Réglages modifiables depuis Neovim. Rien n'est écrit sur disque : les valeurs retombent sur
---celles de la spec Lazy au prochain démarrage.

---@class Ui
local M = {}

local client = require("tts-nvim.client")
local config = require("tts-nvim.config")

---@class ui.setting
---@field key string Clé affichée
---@field value fun(): string Valeur courante, formatée
---@field edit fun(done: fun()) Ouvre l'édition, appelle `done` quand la valeur a changé

---Sélection générique : Snacks si disponible, `vim.ui.select` sinon — le repli garde les
---commandes utilisables en mode headless et sans Snacks chargé.
---@generic T
---@param items T[]
---@param opts { title: string, format: fun(item: T): string }
---@param on_choice fun(item: T?)
local function select(items, opts, on_choice)
	if Snacks and Snacks.picker then
		Snacks.picker.pick({
			title = opts.title,
			layout = { preset = "select" },
			finder = function(_, ctx)
				local entries = {} ---@type table[]
				for index, item in ipairs(items) do
					table.insert(entries, { idx = index, text = opts.format(item), item = item })
				end
				return ctx.filter:filter(entries)
			end,
			format = function(entry)
				return { { entry.text } }
			end,
			confirm = function(picker, entry)
				picker:close()
				on_choice(entry and entry.item or nil)
			end,
		})
		return
	end

	vim.ui.select(items, { prompt = opts.title, format_item = opts.format }, on_choice)
end

---Demande un nombre, en refusant ce qui n'en est pas un.
---@param prompt string
---@param current number
---@param validate fun(value: number): boolean, string?
---@param on_valid fun(value: number)
local function input_number(prompt, current, validate, on_valid)
	vim.ui.input({ prompt = prompt, default = tostring(current) }, function(answer)
		if not answer or answer == "" then
			return
		end

		local value = tonumber(answer)
		if not value then
			vim.notify("tts-nvim : « " .. answer .. " » n'est pas un nombre", vim.log.levels.ERROR)
			return
		end

		local ok, err = validate(value)
		if not ok then
			vim.notify("tts-nvim : " .. (err or "valeur invalide"), vim.log.levels.ERROR)
			return
		end

		on_valid(value)
	end)
end

---Choisit la voix parmi les modèles réellement présents chez le démon.
---Le catalogue vit sur la machine du démon : Neovim ne peut pas le deviner.
---@param on_done? fun()
function M.pick_voice(on_done)
	client.request({ op = "voices" }, function(response, err)
		if err or not response or not response.voices then
			return
		end

		if #response.voices == 0 then
			vim.notify(
				"tts-nvim : aucun modèle chez le démon — voir daemon/README.md",
				vim.log.levels.WARN
			)
			return
		end

		select(response.voices, {
			title = "󰔊 Voix Piper",
			format = function(voice)
				return voice == config.current_voice() and ("● " .. voice) or ("  " .. voice)
			end,
		}, function(voice)
			if not voice then
				return
			end
			config.voice = voice
			vim.notify("tts-nvim : voix " .. voice, vim.log.levels.INFO)
			if on_done then
				on_done()
			end
		end)
	end)
end

---@param on_done? fun()
function M.set_speed(on_done)
	input_number("Vitesse (1.0 = nominale) : ", config.speed, function(value)
		if value <= 0 then
			return false, "la vitesse doit être strictement positive"
		end
		return true
	end, function(value)
		config.speed = value
		if on_done then
			on_done()
		end
	end)
end

---@param on_done? fun()
function M.set_volume(on_done)
	input_number("Volume (0.0 à 1.0) : ", config.volume, function(value)
		if value < 0 or value > 1 then
			return false, "le volume doit être compris entre 0.0 et 1.0"
		end
		return true
	end, function(value)
		config.volume = value
		if on_done then
			on_done()
		end
	end)
end

---Change la cible du démon. Accepte « port » ou « hôte:port ».
---@param spec? string
---@param on_done? fun()
function M.set_target(spec, on_done)
	local function apply(answer)
		if not answer or answer == "" then
			return
		end

		local host, port = answer:match("^(.-):(%d+)$")
		if not host then
			port = answer:match("^(%d+)$")
			host = config.host
		end

		if not port then
			vim.notify("tts-nvim : cible attendue sous la forme « hôte:port » ou « port »", vim.log.levels.ERROR)
			return
		end

		config.host = host ~= "" and host or config.host
		config.port = tonumber(port)
		vim.notify(("tts-nvim : cible %s:%d"):format(config.host, config.port), vim.log.levels.INFO)
		if on_done then
			on_done()
		end
	end

	if spec and spec ~= "" then
		apply(spec)
		return
	end

	vim.ui.input({ prompt = "Cible du démon : ", default = ("%s:%d"):format(config.host, config.port) }, apply)
end

---@return ui.setting[]
---@nodiscard
local function settings()
	return {
		{
			key = "Voix",
			value = function()
				return config.current_voice()
			end,
			edit = M.pick_voice,
		},
		{
			key = "Vitesse",
			value = function()
				return ("%.2f"):format(config.speed)
			end,
			edit = M.set_speed,
		},
		{
			key = "Volume",
			value = function()
				return ("%.2f"):format(config.volume)
			end,
			edit = M.set_volume,
		},
		{
			key = "Cible",
			value = function()
				return ("%s:%d"):format(config.host, config.port)
			end,
			edit = function(done)
				M.set_target(nil, done)
			end,
		},
	}
end

---Ouvre la liste des réglages ; valider une entrée l'édite, puis rouvre la liste.
function M.open()
	select(settings(), {
		title = "󰔊 Réglages TTS",
		format = function(setting)
			return ("%-8s %s"):format(setting.key, setting.value())
		end,
	}, function(setting)
		if not setting then
			return
		end
		setting.edit(function()
			vim.schedule(M.open)
		end)
	end)
end

return M
