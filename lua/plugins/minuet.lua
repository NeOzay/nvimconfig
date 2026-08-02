-- Complétion IA (remplace copilot.lua) — DeepSeek via l'API compatible OpenAI.
-- La clé est lue dans `.env` à la racine de la config (non suivi par git) :
--   DEEPSEEK_API_KEY=sk-...
--
-- Note : le provider `openai_fim_compatible` (endpoint /beta/completions) offre
-- une meilleure complétion « fill-in-the-middle », mais l'endpoint FIM beta de
-- DeepSeek ne sert que `deepseek-chat`. `deepseek-v4-flash` n'étant exposé que
-- par l'API chat, on passe par `openai_compatible`.

---@type LazyPluginSpec
return {
	"milanglacier/minuet-ai.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	-- Chargé au démarrage : le ghost text doit s'armer sans attendre un autre plugin
	event = { "InsertEnter", "VeryLazy" },
	cmd = "Minuet",
	opts = {
		provider = "openai_fim_compatible",
		n_completions = 1,
		context_window = 4096,
		request_timeout = 3,
		throttle = 1500,
		debounce = 600,
		notify = "warn",
		provider_options = {
			openai_fim_compatible = {
				name = "deepseek",
				-- end_point = "https://api.deepseek.com/v1/chat/completions",
				-- model = "deepseek-v4-flash",
				api_key = function()
					return require("utils.env").get("DEEPSEEK_API_KEY") or ""
				end,
				-- stream = true,
				optional = {
					max_tokens = 256,
					top_p = 0.9,
					-- INDISPENSABLE : `deepseek-v4-flash` raisonne par défaut. En stream,
					-- il n'émet que `delta.reasoning_content` pendant plusieurs secondes et
					-- `delta.content` reste nil — minuet coupe la requête à `request_timeout`
					-- et n'affiche donc jamais rien.
					thinking = { type = "disabled" },
				},
			},
		},
		-- Rendu principal : ghost text inline (comme copilot.lua).
		-- La source blink reste disponible en déclenchement manuel (<A-y>).
		virtualtext = {
			auto_trigger_ft = { "*" },
			auto_trigger_ignore_ft = {
				"codecompanion",
				"markdown",
				"gitcommit",
				"NeogitCommitMessage",
				"snacks_picker_input",
				"TelescopePrompt",
				"minifiles",
				"trouble",
				"aerial",
			},
			-- Le ghost text reste affiché même quand le menu blink est ouvert
			show_on_completion_menu = true,
			-- Mappings volontairement hors du champ de blink (Tab/S-Tab/CR/C-y/C-e/C-space)
			keymap = {
				accept = "<A-a>",
				accept_line = "<A-l>",
				accept_n_lines = "<A-z>",
				next = "<A-n>",
				prev = "<A-p>",
				dismiss = "<A-e>",
			},
		},
	},
	config = function(_, opts)
		require("minuet").setup(opts)
		-- Recale les suggestions arrivées après coup sur le texte tapé entre-temps
		require("utils.minuet_typing").setup()
	end,
}
