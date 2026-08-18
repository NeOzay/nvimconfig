if vim.g.loaded_tts_nvim then
	return
end
vim.g.loaded_tts_nvim = true

vim.api.nvim_create_user_command("TTS", function()
	require("tts-nvim").tts()
end, { range = true, desc = "Lire la sélection à voix haute" })

vim.api.nvim_create_user_command("TTSFile", function()
	require("tts-nvim").tts_to_file()
end, { range = true, desc = "Écrire la synthèse de la sélection dans un fichier" })

vim.api.nvim_create_user_command("TTSStop", function()
	require("tts-nvim").tts_stop()
end, { desc = "Interrompre la lecture en cours" })

vim.api.nvim_create_user_command("TTSSetLanguage", function(args)
	require("tts-nvim").tts_set_language(args)
end, {
	nargs = 1,
	desc = "Changer la langue de lecture",
	complete = function()
		return require("tts-nvim").get_supported_languages()
	end,
})

vim.api.nvim_create_user_command("TTSSetBackend", function(args)
	require("tts-nvim").tts_set_backend(args)
end, {
	nargs = 1,
	desc = "Changer le backend de synthèse",
	complete = function()
		return require("tts-nvim").get_available_backends()
	end,
})

vim.api.nvim_create_user_command("TTSConfig", function()
	require("tts-nvim.ui").open()
end, { desc = "Régler le TTS (session courante)" })

vim.api.nvim_create_user_command("TTSVoice", function()
	require("tts-nvim.ui").pick_voice()
end, { desc = "Choisir la voix parmi les modèles du démon" })

vim.api.nvim_create_user_command("TTSSpeed", function()
	require("tts-nvim.ui").set_speed()
end, { desc = "Régler la vitesse de lecture" })

vim.api.nvim_create_user_command("TTSVolume", function()
	require("tts-nvim.ui").set_volume()
end, { desc = "Régler le volume" })

vim.api.nvim_create_user_command("TTSTarget", function(args)
	require("tts-nvim.ui").set_target(args.args)
end, { nargs = "?", desc = "Changer la cible du démon (hôte:port)" })
