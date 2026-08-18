---@namespace tts-nvim

---Client du démon de synthèse. Une requête = une connexion TCP sur la boucle locale, une ligne
---JSON envoyée, une ligne JSON reçue. La connexion n'est jamais maintenue : sans cela, une
---coupure du tunnel SSH laisserait un client persuadé d'être connecté.

---@class Client
local M = {}

local config = require("tts-nvim.config")

local uv = vim.uv

---@class client.response
---@field ok boolean
---@field error? string
---@field path? string Chemin écrit, pour l'opération `save`
---@field voices? string[] Modèles disponibles, pour l'opération `voices`

---@alias client.callback fun(response: client.response?, err: string?)

---Encode une requête en une ligne JSON.
---@param payload table
---@return string
---@nodiscard
function M.encode(payload)
	return vim.json.encode(payload) .. "\n"
end

---Décode une réponse. Retourne nil si la ligne n'est pas du JSON exploitable.
---@param line string
---@return client.response?
---@nodiscard
function M.decode(line)
	local ok, decoded = pcall(vim.json.decode, vim.trim(line))
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	return decoded
end

---@param message string
---@param level integer
local function notify(message, level)
	vim.schedule(function()
		vim.notify("tts-nvim : " .. message, level)
	end)
end

---Envoie une requête au démon.
---
---L'échec de connexion n'est pas une erreur Lua : c'est le cas nominal quand Neovim tourne sur
---une machine distante sans tunnel actif. Il se signale par une notification.
---@param payload table
---@param on_response? client.callback
---@param opts? { host?: string, port?: integer, timeout_ms?: integer }
function M.request(payload, on_response, opts)
	opts = opts or {}
	local host = opts.host or config.host
	local port = opts.port or config.port
	local timeout_ms = opts.timeout_ms or config.timeout_ms

	local tcp = uv.new_tcp()
	if not tcp then
		notify("impossible d'ouvrir une socket", vim.log.levels.ERROR)
		return
	end

	local timer = uv.new_timer()
	local buffer = ""
	local settled = false

	---@param response client.response?
	---@param err string?
	local function settle(response, err)
		if settled then
			return
		end
		settled = true

		if timer and not timer:is_closing() then
			timer:stop()
			timer:close()
		end
		if not tcp:is_closing() then
			tcp:close()
		end

		if err then
			notify(err, vim.log.levels.WARN)
		end
		if on_response then
			vim.schedule(function()
				on_response(response, err)
			end)
		end
	end

	if timer then
		timer:start(timeout_ms, 0, function()
			settle(nil, ("aucune réponse de %s:%d après %d ms"):format(host, port, timeout_ms))
		end)
	end

	tcp:connect(host, port, function(connect_err)
		if connect_err then
			settle(nil, ("démon injoignable sur %s:%d (%s)"):format(host, port, connect_err))
			return
		end

		tcp:write(M.encode(payload), function(write_err)
			if write_err then
				settle(nil, ("échec d'envoi vers %s:%d (%s)"):format(host, port, write_err))
			end
		end)

		tcp:read_start(function(read_err, chunk)
			if read_err then
				settle(nil, ("échec de lecture depuis %s:%d (%s)"):format(host, port, read_err))
				return
			end

			-- Fin de flux sans ligne complète : le démon a fermé sans répondre.
			if not chunk then
				settle(nil, buffer == "" and ("connexion fermée par %s:%d sans réponse"):format(host, port) or nil)
				return
			end

			buffer = buffer .. chunk
			local newline = buffer:find("\n", 1, true)
			if not newline then
				return
			end

			local response = M.decode(buffer:sub(1, newline - 1))
			if not response then
				settle(nil, "réponse illisible du démon")
			elseif response.ok == false then
				settle(response, response.error or "le démon a signalé une erreur")
			else
				settle(response, nil)
			end
		end)
	end)
end

return M
