+++
id = "listdir-sans-tests"
title = "Le plugin `listdir` ne livre aucun test, dans un dépôt qui en a le cadre"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

Aucun test pour le plugin :

```
$ find tests -name 'test_*.lua' | sort
tests/lsp/hover/test_format.lua
tests/tts/test_daemon_io.lua
tests/tts/test_protocol.lua
tests/tts/test_selection.lua
$ test -d tests/listdir && echo existe || echo absent
absent
```

Le cadre existe pourtant, et la suite passe :

```
$ grep -rcE '^T(\[.*\])+ = function' tests/tts/*.lua tests/lsp/hover/*.lua
tests/tts/test_daemon_io.lua:8
tests/tts/test_protocol.lua:16
tests/tts/test_selection.lua:5
tests/lsp/hover/test_format.lua:31
$ make test 2>&1 | tail -1
Fails (0) and Notes (0)
```

8 + 16 + 5 + 31 = **60 cas**, exactement le chiffre qu'avançait l'entrée.

## Verdict

Le constat tient dans ses deux volets : `plugins/listdir/` n'a toujours aucun test, et le dépôt en
fait bien tourner 60 par `make test`, tous verts. Le chiffre de l'entrée est vérifié, pas seulement
repris.

`pertinent`. Ce n'est pas `pas-une-dette` : l'entrée ne demande pas une couverture de principe mais
nomme quatre fonctions pures et vérifiables, et la conséquence décrite — des commandes headless
jetables à réécrire à chaque évolution — s'est déjà produite pendant cette revue même, où la fiche
`listdir-front-matter-non-referme` a dû reconstruire une vérification à la main.

## Action

Reste au registre avec ses deux champs de revue. **Correction de contenu à arbitrer** : le **Pour
solder** nomme `item.parse`, qui n'existe pas dans l'API publique — c'est `item.read`. Même
correction que sur `listdir-front-matter-non-referme`.

## Arbitrage

**2026-08-29 — correction autorisée.** `item.parse` → `item.read` dans le Pour solder, même motif
que sur [[listdir-front-matter-non-referme]].
