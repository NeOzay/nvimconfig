+++
id = "verification-etape-2-clause-perdue"
title = "La vérification de l'étape 2 a perdu une clause du plan"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

L'étape 2 du suivi archivé, telle qu'elle a été écrite — sans la clause `! grep -rqi 'openai\|edge'` :

```
$ grep -n '^- \[x\] 2\.' .claude/implementation/done/2026-08-18-tts-piper.md
53:- [x] 2. Élagage du clone vers Piper seul — … — vérif: `! grep -rq '^M = {}' plugins/tts.nvim/lua/ && nvim --headless -c "lua assert(loadfile('plugins/tts.nvim/lua/tts-nvim/backends.lua'))" -c qa`
```

Aucune justification de l'écart nulle part dans le suivi :

```
$ grep -nic 'clause\|assouplis' .claude/implementation/done/2026-08-18-tts-piper.md
0
```

La clause disparue, rejouée aujourd'hui — elle échouerait toujours :

```
$ grep -rqi 'openai\|edge' plugins/tts.nvim/ && echo "match trouvé, la clause ! grep échouerait"
match trouvé, la clause ! grep échouerait
```

## Verdict

Le constat tient dans ses trois volets : la clause est absente de l'étape telle qu'archivée, l'écart
n'est justifié ni dans l'étape ni au journal (`grep` rend 0 occurrence), et la clause échouerait
encore aujourd'hui — sur `LICENSE` seul, ce qui est l'entrée `license-mentionne-edge-tts`.

Ce n'est pas un doublon de cette dernière : celle-ci porte sur le fichier fautif, celle-là sur une
vérification affaiblie sans trace. Les deux se soldent séparément, et la seconde ne peut l'être
qu'après la première.

## Action

Rien à écrire au registre hors les deux champs de revue. Dépendance à noter : le **Pour solder**
(« rétablir la clause une fois le `LICENSE` corrigé ») suppose `license-mentionne-edge-tts` soldée
d'abord.

## Arbitrage

<OPTIONNEL>
