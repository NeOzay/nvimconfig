+++
id = "ttsvoice-fige-la-deduction-par-langue"
title = "`:TTSVoice` rend `:TTSSetLanguage` définitivement sans effet"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/tts.nvim/lua/tts-nvim/config.lua`, `M.current_voice()` — sa première clause, `if M.voice
then return M.voice end` : dès que `config.voice` est posé par `:TTSVoice`, `current_voice()` le
renvoie toujours et la déduction par langue est court-circuitée pour toute la session.
`M.tts_set_language` (`plugins/tts.nvim/lua/tts-nvim/init.lua`) notifie pourtant
`langue fr (fr_FR-siwis-medium)` — une voix qui ne sera pas utilisée.

## Pourquoi c'est gênant

Aucun moyen de revenir au mode « voix déduite de la langue » sans redémarrer Neovim, et le message
affirme le contraire du comportement réel.

## Pour solder

Permettre à `:TTSVoice` de reprendre la valeur vide pour remettre `config.voice` à `nil`, et faire
dire à la notification de `:TTSSetLanguage` quelle voix sera *effectivement* utilisée.

*Identifié par `implementation-auditor`, R3 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
