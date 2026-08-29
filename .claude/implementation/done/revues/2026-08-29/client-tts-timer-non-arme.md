+++
id = "client-tts-timer-non-arme"
title = "Le délai de garde du client TTS n'est pas armé si `uv.new_timer()` échoue"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

```
$ grep -n -B1 -A4 'if timer then' plugins/tts.nvim/lua/tts-nvim/client.lua
99:	if timer then
100-		timer:start(timeout_ms, 0, function()
101-			settle(nil, ("aucune réponse de %s:%d après %d ms"):format(host, port, timeout_ms))
102-		end)
103-	end
```

Le voisin immédiat, qui traite l'échec autrement, est toujours là lui aussi :

```
$ sed -n '63,68p' plugins/tts.nvim/lua/tts-nvim/client.lua
	local tcp = uv.new_tcp()
	if not tcp then
		notify("impossible d'ouvrir une socket", vim.log.levels.ERROR)
		return
	end
```

## Verdict

Le constat tient intégralement. Le `if timer then` n'a pas de branche `else` : si
`uv.new_timer()` rend `nil`, aucun délai n'est armé, aucune notification n'est émise et
`on_response` n'est jamais appelé. L'asymétrie avec `uv.new_tcp()`, qui notifie puis `return`, est
inchangée depuis le constat d'origine.

Ni `a-solder` (rien n'a été corrigé) ni `pas-une-dette` : c'est bien un chemin d'échec silencieux
dans du code livré, et l'incohérence avec le cas voisin lui donne un critère objectif.

## Action

Rien à écrire au registre hors les deux champs de revue : l'entrée reste où elle est.

## Arbitrage

<OPTIONNEL>
