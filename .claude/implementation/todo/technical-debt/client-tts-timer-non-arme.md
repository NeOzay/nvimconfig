+++
id = "client-tts-timer-non-arme"
title = "Le délai de garde du client TTS n'est pas armé si `uv.new_timer()` échoue"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/tts.nvim/lua/tts-nvim/client.lua` : le `if timer then` qui garde `timer:start(timeout_ms,
…)` laisse la requête sans délai si la création du timer échoue, sans notifier ni appeler
`on_response` — alors que l'échec de `uv.new_tcp()` juste au-dessus, lui, notifie
(`impossible d'ouvrir une socket`, puis `return`).

## Pourquoi c'est gênant

Chemin d'échec silencieux : la requête reste pendante indéfiniment. Très improbable, mais
l'incohérence avec le cas voisin est ce qui le rend notable.

## Pour solder

Notifier et abandonner comme pour `uv.new_tcp()`.

*Identifié par `implementation-auditor`, R8 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
