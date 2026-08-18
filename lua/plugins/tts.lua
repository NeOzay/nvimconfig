---@type LazyPluginSpec
return {
	dir = vim.fn.stdpath("config") .. "/plugins/tts.nvim",
	cmd = {
		"TTS",
		"TTSFile",
		"TTSStop",
		"TTSConfig",
		"TTSVoice",
		"TTSSpeed",
		"TTSVolume",
		"TTSTarget",
		"TTSSetLanguage",
		"TTSSetBackend",
	},
	---@type Partial<tts-nvim.config>
	opts = {
		language = "fr",
		remove_syntax = true,
	},
	config = function(_, opts)
		require("tts-nvim").setup(opts)
	end,
}
