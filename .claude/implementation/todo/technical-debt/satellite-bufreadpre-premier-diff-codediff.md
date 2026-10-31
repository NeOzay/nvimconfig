+++
id = "satellite-bufreadpre-premier-diff-codediff"
title = "Le chargement de satellite au premier BufReadPre fait échouer le premier diff de codediff (E201)"
date = 2026-10-31
severite = "avertissement"
chantier = "codediff-explorer"
reference = "journal du suivi, entrée « Hors périmètre : satellite »"
pin = false
reviewed = "<OPTIONNEL date>"
category = "<OPTIONNEL>"
+++

## Constat

`lua/plugins/satellite.lua` charge satellite sur `event = "BufReadPre"`. Au premier fichier lu de
la session, son chargement dessine dans les autres fenêtres (`nvim_win_call`) pendant l'autocmd ;
Neovim refuse alors le `:edit` en cours (`E201: *ReadPre autocommands must not change current
buffer`). Quand ce premier fichier est celui d'un diff codediff, la mise à jour s'arrête avant
`commit_update` : focus non rendu, buffer hors session.

Établi par : `nvim --headless` à froid dans un dépôt modifié, `:CodeDiff` → E201 depuis
`codediff/ui/view/helpers.lua` (`open_modified_for_update`) ; précharger satellite, ou le passer
sur `BufReadPost`, fait disparaître l'erreur.

## Pourquoi c'est gênant

Lancer Neovim puis `<leader>gd` sans avoir lu de fichier donne un premier diff cassé, sans autre
signe que l'erreur. Les essais headless de codediff doivent lire un fichier avant `:CodeDiff`.

## Pour solder

Charger satellite sur `BufReadPost` (essayé pendant le chantier, il se charge bien à l'ouverture
d'un fichier) ou après le démarrage, puis vérifier : `nvim --headless` à froid, `:CodeDiff` dans
un dépôt modifié, aucune E201 et focus rendu à l'explorateur.

## Assumé

Hors périmètre de `codediff-explorer` ; l'utilisateur a préféré garder `BufReadPre` dans ce
chantier.
