+++
id = "text-processor-defauts-upstream"
title = "`text_processor.lua` porte deux défauts hérités de l'upstream"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

Point (a), le motif de lien markdown — **corrigé** :

```
$ grep -n 'gsub("%\[' plugins/tts.nvim/lua/tts-nvim/text_processor.lua
44:    text = text:gsub("%[(.-)%]%((.-)%)", "%1")

$ git log --oneline -1 -- plugins/tts.nvim/lua/tts-nvim/text_processor.lua
818270d fix(tts): corriger le pattern gsub des liens markdown
```

Point (b), l'appel bloquant — **toujours là** :

```
$ grep -n ':wait()' plugins/tts.nvim/lua/tts-nvim/text_processor.lua
20:	}):wait()
```

Le style upstream aussi :

```
$ grep -c '^    [^ ]' plugins/tts.nvim/lua/tts-nvim/text_processor.lua   # lignes à 4 espaces
37
$ grep -c '^	' plugins/tts.nvim/lua/tts-nvim/text_processor.lua          # lignes à tabulation
13
$ grep -c 'M\.[a-z_]* = function' plugins/tts.nvim/lua/tts-nvim/text_processor.lua
3
```

## Verdict

L'entrée décrit deux défauts, et **un seul survit**. Le (a) a été soldé par le commit `818270d` du
2026-08-23, hors de tout chantier tracé. Le (b) — `vim.system(…):wait()` bloquant dans la boucle
d'événements — et le style upstream (37 lignes à 4 espaces contre 13 à tabulation, 3 fonctions en
`M.x = function`) sont intacts.

`pertinent` et non `a-solder` : la catégorie juge le fait, et le fait subsiste pour l'essentiel.
Solder l'entrée entière ferait disparaître le défaut bloquant avec l'air de l'avoir réparé.

C'est en revanche un cas de **correction de contenu** : l'entrée est vraie mais partiellement mal
écrite, et son **Constat** comme son **Pour solder** décrivent encore le (a) comme ouvert. La note
de migration posée dans l'entrée le signale déjà, sans le trancher — c'était le rôle de cette revue.

## Action

Reste au registre, avec ses deux champs de revue. Correction de contenu à arbitrer : retirer le
point (a) du **Constat** et du **Pour solder**, absorber la note de migration, et laisser `date` et
`id` inchangés. Le titre parle de « deux défauts » — s'il est corrigé, il faudra dire pourquoi dans
le Constat, l'entrée n'étant plus que sur un seul.

## Arbitrage

**2026-08-29 — décision suivie.** L'utilisateur confirme le classement `pertinent` : l'entrée reste
au registre plutôt que d'être soldée partiellement. La correction de contenu est autorisée — retrait
du point (a), désormais soldé par `818270d`, du Constat et du Pour solder.
