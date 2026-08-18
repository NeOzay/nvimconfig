-- Aller-retour réel contre le démon, lancé en --dry-run sur un port distinct de celui de
-- production : c'est le protocole complet qui est exercé, pas une imitation en Lua.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local client = require("tts-nvim.client")

local PORT = 7799
local DAEMON = vim.fn.getcwd() .. "/plugins/tts.nvim/daemon/tts-piperd.py"

-- Voix factices : le démon ne contrôle que la présence des fichiers avant de répondre, jamais
-- leur contenu. Les tests n'ont donc besoin ni de Piper ni d'un vrai modèle, et ne dépendent pas
-- de ce qui est installé sur la machine.
local VOICE = "test-voice" -- .onnx + .onnx.json : complète
local HALF_VOICE = "half-voice" -- .onnx seul : téléchargement interrompu

local daemon = nil ---@type vim.SystemObj?
local voices_dir = nil ---@type string?

---Appelle le démon et attend la réponse.
---@param payload table
---@return table? response, string? err
local function roundtrip(payload)
	local response, err, done = nil, nil, false

	client.request(payload, function(res, e)
		response, err, done = res, e, true
	end, { port = PORT, timeout_ms = 3000 })

	local ok = vim.wait(5000, function()
		return done
	end, 20)
	if not ok then
		return nil, "le test a expiré avant la réponse"
	end
	return response, err
end

local T = new_set({
	hooks = {
		pre_once = function()
			voices_dir = vim.fn.tempname()
			vim.fn.mkdir(voices_dir, "p")
			for _, name in ipairs({ VOICE .. ".onnx", VOICE .. ".onnx.json", HALF_VOICE .. ".onnx" }) do
				assert(io.open(vim.fs.joinpath(voices_dir, name), "w")):close()
			end

			daemon = vim.system({
				"python3",
				DAEMON,
				"--dry-run",
				"--port",
				tostring(PORT),
				"--voices-dir",
				voices_dir,
			})

			-- Attendre que le port accepte les connexions plutôt que dormir une durée fixe.
			local up = vim.wait(10000, function()
				local probe = vim.uv.new_tcp()
				if not probe then
					return false
				end
				local connected = false
				probe:connect("127.0.0.1", PORT, function(err)
					connected = err == nil
				end)
				vim.wait(100, function()
					return connected
				end, 10)
				if not probe:is_closing() then
					probe:close()
				end
				return connected
			end, 100)

			if not up then
				error("le démon n'a pas démarré sur le port " .. PORT)
			end
		end,
		post_once = function()
			if daemon then
				daemon:kill(15)
				daemon:wait(5000)
			end
			if voices_dir then
				vim.fn.delete(voices_dir, "rf")
			end
		end,
	},
})

T["voices"] = function()
	local response, err = roundtrip({ op = "voices" })
	expect.equality(err, nil)
	expect.equality(response.ok, true)
	expect.equality(type(response.voices), "table")
end

T["speak"] = function()
	local response, err = roundtrip({
		op = "speak",
		text = "bonjour",
		voice = VOICE,
		speed = 1.0,
		volume = 1.0,
	})
	expect.equality(err, nil)
	expect.equality(response.ok, true)
end

T["speak accentué"] = function()
	local response = roundtrip({
		op = "speak",
		text = "Été à Noël, ça se dit sans problème",
		voice = VOICE,
		speed = 1.0,
	})
	expect.equality(response.ok, true)
end

T["stop"] = function()
	local response, err = roundtrip({ op = "stop" })
	expect.equality(err, nil)
	expect.equality(response.ok, true)
end

T["texte vide refusé"] = function()
	local response, err = roundtrip({ op = "speak", text = "", voice = VOICE })
	expect.equality(response.ok, false)
	expect.equality(type(err), "string")
end

T["voix absente refusée"] = function()
	local response, err = roundtrip({ op = "speak", text = "bonjour", voice = "nexiste-pas" })
	expect.equality(response.ok, false)
	expect.equality(type(err), "string")
	expect.equality(err:find("modèle introuvable", 1, true) ~= nil, true)
end

T["voix incomplète refusée"] = function()
	-- Le .onnx est là, le .onnx.json manque : Piper échouerait au chargement, hors de la requête,
	-- et le symptôme se réduirait à « aucun son ».
	local response, err = roundtrip({ op = "speak", text = "bonjour", voice = HALF_VOICE })
	expect.equality(response.ok, false)
	expect.equality(err:find(".onnx.json", 1, true) ~= nil, true)
end

T["opération inconnue refusée"] = function()
	local response = roundtrip({ op = "nawak" })
	expect.equality(response.ok, false)
end

return T
