+++
id = "ttsvoice-fige-la-deduction-par-langue"
title = "`:TTSVoice` rend `:TTSSetLanguage` définitivement sans effet"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

La clause qui court-circuite la déduction :

```
$ sed -n '63,69p' plugins/tts.nvim/lua/tts-nvim/config.lua
function M.current_voice()
	if M.voice then
		return M.voice
	end
	local per_backend = M.languages_to_voice[M.backend]
	return (per_backend and per_backend[M.language]) or M.piper_model
end
```

Le seul endroit qui pose `config.voice`, et qui n'offre aucun moyen de le remettre à `nil` — un
choix vide sort par `return` avant l'affectation :

```
$ grep -rn 'config.voice = ' plugins/tts.nvim/lua/tts-nvim/
plugins/tts.nvim/lua/tts-nvim/ui.lua:102:			config.voice = voice
```

La notification trompeuse, inchangée :

```
$ sed -n '78,79p' plugins/tts.nvim/lua/tts-nvim/init.lua
	if voice then
		vim.notify(("tts-nvim : langue %s (%s)"):format(lang, voice), vim.log.levels.INFO)
```

## Verdict

Les deux moitiés du constat tiennent. `current_voice()` rend `M.voice` dès qu'il est posé, et le
picker de `ui.lua` est le seul chemin d'écriture : il `return` sur un choix vide au lieu de remettre
`config.voice` à `nil`, donc rien ne permet de revenir au mode déduit sans redémarrer Neovim.
`tts_set_language` continue par ailleurs d'annoncer la voix cartographiée, que `current_voice()`
n'utilisera pas.

## Action

Rien à écrire au registre hors les deux champs de revue. Le **Pour solder** est actionnable, et son
premier volet — « permettre à `:TTSVoice` de reprendre la valeur vide » — se lit désormais plus
précisément : c'est le `if not voice then return end` de `ui.lua` qu'il faut distinguer d'un
véritable effacement.

## Arbitrage

<OPTIONNEL>
