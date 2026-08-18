local new_set = MiniTest.new_set
local expect = MiniTest.expect

local backends = require("tts-nvim.backends")
local client = require("tts-nvim.client")
local config = require("tts-nvim.config")

local T = new_set({
	hooks = {
		pre_case = function()
			config.setup({})
		end,
	},
})

-- ============================================================
-- Encodage / décodage
-- ============================================================
T["encode"] = new_set()

T["encode"]["termine par un saut de ligne"] = function()
	local encoded = client.encode({ op = "stop" })
	expect.equality(encoded:sub(-1), "\n")
end

T["encode"]["produit du JSON relisible"] = function()
	local decoded = client.decode(client.encode({ op = "speak", text = "bonjour" }))
	expect.equality(decoded.op, "speak")
	expect.equality(decoded.text, "bonjour")
end

T["encode"]["préserve les accents"] = function()
	local decoded = client.decode(client.encode({ text = "été à Noël" }))
	expect.equality(decoded.text, "été à Noël")
end

T["decode"] = new_set()

T["decode"]["tolère les espaces de fin"] = function()
	local decoded = client.decode('{"ok":true}  \n')
	expect.equality(decoded.ok, true)
end

T["decode"]["retourne nil sur du non-JSON"] = function()
	expect.equality(client.decode("pas du json"), nil)
end

T["decode"]["retourne nil sur un scalaire JSON"] = function()
	expect.equality(client.decode("42"), nil)
end

-- ============================================================
-- Construction de la requête
-- ============================================================
T["build_request"] = new_set()

T["build_request"]["porte les réglages courants"] = function()
	config.speed = 1.5
	config.volume = 0.4
	local request = backends.get_backend("piper").build_request(config, "salut")

	expect.equality(request.op, "speak")
	expect.equality(request.text, "salut")
	expect.equality(request.speed, 1.5)
	expect.equality(request.volume, 0.4)
end

T["build_request"]["déduit la voix de la langue"] = function()
	config.voice = nil
	config.language = "fr"
	-- Lire la voix attendue dans la config plutôt que la figer : c'est la déduction qu'on teste,
	-- pas le modèle du moment, qui reste un réglage de goût.
	local expected = config.languages_to_voice[config.backend]["fr"]
	expect.equality(backends.get_backend("piper").build_request(config, "x").voice, expected)
end

T["build_request"]["une voix explicite l'emporte sur la langue"] = function()
	config.language = "fr"
	config.voice = "en_US-lessac-medium"
	expect.equality(backends.get_backend("piper").build_request(config, "x").voice, "en_US-lessac-medium")
	config.voice = nil
end

T["build_request"]["se rabat sur piper_model pour une langue inconnue"] = function()
	config.voice = nil
	config.language = "kl"
	expect.equality(backends.get_backend("piper").build_request(config, "x").voice, config.piper_model)
end

-- ============================================================
-- Validation
-- ============================================================
T["validate_config"] = new_set()

T["validate_config"]["accepte la configuration par défaut"] = function()
	expect.equality(backends.get_backend("piper").validate_config(config), true)
end

T["validate_config"]["refuse une vitesse nulle"] = function()
	config.speed = 0
	expect.equality(backends.get_backend("piper").validate_config(config), false)
end

T["validate_config"]["refuse un volume hors bornes"] = function()
	config.volume = 1.5
	expect.equality(backends.get_backend("piper").validate_config(config), false)
end

T["backends"] = new_set()

T["backends"]["n'expose que piper"] = function()
	expect.equality(backends.get_available_backends(), { "piper" })
end

T["backends"]["retourne nil sur un nom inconnu"] = function()
	expect.equality(backends.get_backend("edge"), nil)
end

-- ============================================================
-- Cible injoignable — le cas « pas de tunnel SSH »
-- ============================================================
T["injoignable"] = new_set()

T["injoignable"]["rapporte une erreur sans lever"] = function()
	local done, seen_err = false, nil

	-- Port fermé : c'est exactement ce que voit Neovim sur le VPS sans RemoteForward.
	client.request({ op = "voices" }, function(_, err)
		seen_err = err
		done = true
	end, { port = 7801, timeout_ms = 500 })

	expect.equality(vim.wait(3000, function()
		return done
	end, 20), true)
	expect.equality(type(seen_err), "string")
end

return T
