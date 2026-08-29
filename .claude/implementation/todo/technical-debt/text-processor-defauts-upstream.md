+++
id = "text-processor-defauts-upstream"
title = "`text_processor.lua` porte deux défauts hérités de l'upstream"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

`plugins/tts.nvim/lua/tts-nvim/text_processor.lua` : la fonction locale `pandoc()` appelle
`vim.system({ "pandoc", … }):wait()` de façon **bloquante** dans la boucle d'événements. Le module
est aussi le seul du plugin resté au style upstream — 4 espaces là où le dépôt est en tabulations,
commentaires en anglais, `M.x = function(…)` au lieu de `function M.x(…)`, annotations Emmylua
absentes.

Le titre parle de **deux** défauts, et l'entrée n'en porte plus qu'un : le motif de lien markdown
`text:gsub("%[(.-)%]%(.-)", "%1")`, privé de sa parenthèse fermante, a été corrigé le 2026-08-23 par
le commit `818270d`. `title`, `id` et `date` restent inchangés — ils disent depuis quand le problème
est connu et par quoi il se référence, pas ce qu'il en reste.

> **Revue 2026-08-29** — retrait du défaut soldé. Établi par :
> `grep -n 'gsub("%\[' plugins/tts.nvim/lua/tts-nvim/text_processor.lua` →
> `44:    text = text:gsub("%[(.-)%]%((.-)%)", "%1")`, et
> `git log --oneline -1 -- plugins/tts.nvim/lua/tts-nvim/text_processor.lua` → `818270d`.
> Le reste tient : `grep -n ':wait()' …` → `20:	}):wait()` ; `grep -c '^    [^ ]' …` → 37 lignes à
> 4 espaces contre 13 à tabulation.

## Pourquoi c'est gênant

Une grosse sélection avec `syntax_removal_method = "pandoc"` fige Neovim le temps de la conversion.
Le dépôt d'origine ayant été supprimé, personne d'autre ne le corrigera.

## Pour solder

Passer `pandoc()` en asynchrone via le callback de `vim.system`, et aligner le fichier sur le style
du dépôt.

*Identifié par `implementation-auditor`, R4 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
