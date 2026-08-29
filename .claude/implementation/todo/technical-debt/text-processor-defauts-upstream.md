+++
id = "text-processor-defauts-upstream"
title = "`text_processor.lua` porte deux défauts hérités de l'upstream"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/tts.nvim/lua/tts-nvim/text_processor.lua` : (a) le motif de lien markdown
`text:gsub("%[(.-)%]%(.-)", "%1")` n'a pas de parenthèse fermante `%)` et ne consomme donc pas la
cible du lien ; (b) la fonction locale `pandoc()` appelle `vim.system({ "pandoc", … }):wait()` de
façon **bloquante** dans la boucle d'événements. Le module est aussi le seul du plugin resté au
style upstream (4 espaces, commentaires anglais, annotations Emmylua absentes).

> **Note du chantier `debt-registry-migration`** — le constat ci-dessus est celui du 2026-08-18, et
> `date` le porte : il n'est pas redaté. Au passage de la migration, le point (a) ne se vérifiait
> plus — le fichier porte `text:gsub("%[(.-)%]%((.-)%)", "%1")`, corrigé par le commit `818270d`.
> Relevé sans être jugé : le solder relève de la revue. Le point (b) et le style tiennent toujours.

## Pourquoi c'est gênant

L'URL d'un lien markdown est lue à voix haute, et une grosse sélection avec
`syntax_removal_method = "pandoc"` fige Neovim le temps de la conversion. Le dépôt d'origine ayant
été supprimé, personne d'autre ne les corrigera.

## Pour solder

Fermer le motif en `%[(.-)%]%(.-%)`, passer `pandoc()` en asynchrone via le callback de
`vim.system`, et aligner le fichier sur le style du dépôt.

*Identifié par `implementation-auditor`, R4 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
